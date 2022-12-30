const toastLiveExample = document.getElementById('liveToast')
const toastMessage = document.getElementById('toast-message')

function setNotification(message) {
    if (message === 0) {
        toastMessage.innerHTML = "Please Wait! Transaction sent.";
    } else if (message.code) {
        toastMessage.innerHTML = message.data.message;
    } else {
        toastMessage.innerHTML = message;
    }
    const toast = new bootstrap.Toast(toastLiveExample)
    toast.show()
}

/*
const AVALANCHE_MAINNET = {
    chainId: '0xA86A',
    chainName: 'Avalanche Mainnet C-Chain',
    nativeCurrency: {
        name: 'Avalanche',
        symbol: 'AVAX',
        decimals: 18
    },
    rpcUrls: ['https://api.avax.network/ext/bc/C/rpc'],
    blockExplorerUrls: ['https://snowtrace.io/']
}
*/
const AVALANCE_TESTNET = {
    chainId: '0xA869',
    chainName: 'Avalanche Testnet C-Chain',
    nativeCurrency: {
        name: 'Avalanche',
        symbol: 'AVAX',
        decimals: 18
    },
    rpcUrls: ['https://api.avax-test.network/ext/bc/C/rpc'],
    blockExplorerUrls: ['https://testnet.snowtrace.io/']
}

let isMetamask = false;
let metamaskURL = "https://metamask.io/download/";
let contractAddress = "0x9394F583B7b283Fc19F009D2DECe3F6e4789d5A5";
let nftPrice = 0.1;
let account;
let provider;
let contract;
let abi;
let isListenContract;

const activeChain = AVALANCE_TESTNET;

fetch('../abi.json')
    .then((response) => response.json())
    .then((jsonData) => {
        abi = jsonData;
        if (isMetamask) {
            getContractData();
        }
    });

const isChain = (chainId) => (
    chainId &&
    chainId.toLowerCase() === activeChain.chainId.toLowerCase()
)

if (typeof window.ethereum !== 'undefined') {
    // Metamask is installed
    document.getElementById("metamask-button").innerHTML = "Connect Metamask";
    isMetamask = true;

    if (sessionStorage.getItem("connectMetamaskSession")) {
        connectMetamask();
    }
} else {
    // No Metamask
    document.getElementById("metamask-button").innerHTML = "Install Metamask";
}

sessionStorage.removeItem("connectMetamaskSession");

function connectMetamask() {
    if (!account) {
        if (isMetamask) {
            ethereum.request({ method: 'eth_requestAccounts' })
                .then((accounts) => {
                    account = accounts[0];
                    sessionStorage.setItem("connectMetamaskSession", true);
                    document.getElementById("metamask-button").innerHTML = isChain(window.ethereum.chainId) ? (account) : ("Warning : Please connect : " + activeChain.chainName + " !");
                    getContractData();
                })
                .catch((err) => {
                    console.log(err);
                })

        } else {
            window.open(metamaskURL, '_blank');
        }
    }
}

function getContractData() {
    provider = new ethers.providers.Web3Provider(window.ethereum);
    contract = new ethers.Contract(contractAddress, abi, provider);
    contract.getStatus().then((status) => {
        let mintStatus = document.getElementById("mint-status");
        let investmentPeriod = document.getElementById("investment-period");
        if (status[2]) {
            mintStatus.innerHTML = "Open";
            mintStatus.classList.remove('bg-danger')
            mintStatus.classList.add('bg-success')
        } else {
            mintStatus.innerHTML = "Close";
            mintStatus.classList.add('bg-danger')
        }
        investmentPeriod.innerHTML = `${status[0]} / ${status[1]}`
    });
    contract.totalSupply().then((supply) => {
        let totalSupply = document.getElementById("total-supply");
        totalSupply.innerHTML = supply;
        totalSupply.classList.add('bg-secondary');
    });
    if (account) {
        contract.owner().then((owner) => {
            let userAlert = document.getElementById("user-alert");
            let welcomeMessage = document.getElementById("welcome-message");
            userAlert.classList.remove('visually-hidden');
            if (account.toLowerCase() === owner.toLowerCase()) {
                document.getElementById("admin-dropbox").classList.remove('visually-hidden');
                welcomeMessage.innerHTML = "Welcome Admin"
            } else {
                welcomeMessage.innerHTML = `Welcome ${account}`
            }
        });
    }

    if (!isListenContract) {
        listenContract();
        isListenContract = true;
    }
}

function listenContract() {
    const signer = provider.getSigner();
    const connContract = new ethers.Contract(contractAddress, abi, signer);
    connContract.on('*', (event) => {
        if (event.event == "safeMintEvent") {
            if (event.args[0].toLowerCase() == account.toLowerCase()) {
                setNotification(`Congratulations. You minted ${parseInt(event.args[1]._hex, 16)}. nft.<br/><a href='${activeChain.blockExplorerUrls + 'tx/' + event.transactionHash}' target='_blank'>Click</a> to see the process.`)
            }
        } else if (event.event == "startMintEvent") {
            setNotification(`Mint is launched. Start time : ${parseInt(event.args['blockTime']._hex, 16)}`)
        } else if (event.event == "withdrawEvent") {
            setNotification(`The money of the ${parseInt(event.args[2]._hex, 16)}. period, ${(parseInt(event.args[1]._hex, 16) / (10 ** 18)).toFixed(2)} amount of money was withdrawn from the contract.`)
        } else if (event.event == "finishMintEvent") {
            setNotification(`Mint is finished. Finish time : ${parseInt(event.args['blockTime']._hex, 16)}`)
        } else if (event.event == "giveBackNFTEvent") {
            if (event.args[0].toLowerCase() == account.toLowerCase()) {
                setNotification(`The ${parseInt(event.args[1]._hex, 16)}. nft was returned in the ${parseInt(event.args[3]._hex, 16)}. period. ${(parseInt(event.args[2]._hex, 16) / (10 ** 18)).toFixed(2)} AVAX received.`)
            }
        }
        getContractData();
    })
}

if (isMetamask) {
    window.ethereum.on('chainChanged', () => window.location.reload());
    window.ethereum.on('accountsChanged', () => window.location.reload());
}

// Admin Functions

function startMint() {
    const signer = provider.getSigner();
    const connContract = new ethers.Contract(contractAddress, abi, signer);
    connContract.startMint()
        .then((result) => {
            if (result) {
                setNotification(0)
            }
        })
        .catch((error) => {
            setNotification(error);
        });
}

function finishMint() {
    const signer = provider.getSigner();
    const connContract = new ethers.Contract(contractAddress, abi, signer);
    connContract.finishMint()
        .then((result) => {
            if (result) {
                setNotification(0);
            }
        })
        .catch((error) => {
            setNotification(error);
        })
}

function withdrawMoney() {
    const signer = provider.getSigner();
    const connContract = new ethers.Contract(contractAddress, abi, signer);
    connContract.withdraw()
        .then((result) => {
            if (result) {
                setNotification(0);
            }
        })
        .catch((error) => {
            setNotification(error);
        })
}

// User Functions

function mint() {
    const signer = provider.getSigner();
    const connContract = new ethers.Contract(contractAddress, abi, signer);
    let price = nftPrice * (10 ** 18)
    connContract.safeMint({ value: price.toString() })
        .then((result) => {
            if (result) {
                setNotification(0);
            }
        })
        .catch((error) => {
            setNotification(error);
        });
}

function userGiveBackNFT() {
    let tokenId = document.getElementById("input-give-back-nft-id").value;
    const signer = provider.getSigner();
    const connContract = new ethers.Contract(contractAddress, abi, signer);
    connContract.giveBackNFT(tokenId)
        .then((result) => {
            if (result) {
                setNotification(0);
            }
        })
        .catch((error) => {
            setNotification(error);
        })
}