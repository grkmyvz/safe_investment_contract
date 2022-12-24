// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/// @title SafeInvestmentContract
/// @author Görkem YAVUZ
/// @notice It allows to create NFT and invest in projects. It also keeps investors' money safe.

contract SICDemo is ERC721, Ownable {
    using Counters for Counters.Counter;

    /// @dev It keeps the name, that is, the number of nfts created.
    Counters.Counter private _tokenIdCounter;

    /// @dev Variables that are immutable and important to the contract.
    uint256 private constant MAX_SUPPLY = 5; // 1000 Pieces
    uint256 private constant PRICE = 1 * (10**18); // 1 Unit
    uint256 private constant PER_WALLET = 1; // 5 Per wallet
    uint256 private constant PERIOD = 12; // 12 Month period
    uint256 private constant WAIT_PERIOD_TIMESTAMP = 2; // 5 Days timestamp (5 Days : 432000)
    uint256 private constant PER_PERIOD_TIMESTAMP = 10; // 1 Month timestamp (1 Month : 2629743)

    /// @dev When the mint process is finished, these values ​​are assigned and the transactions are made according to these calculated values.
    uint256 private startTimestamp;
    uint256 private perWithdraw;

    /// @dev Variables that hold values ​​to make mint start, end and withdraw for the security of functions.
    bool private mintStart = false;
    bool private mintFinish = false;
    bool private withdrawCheck = false;

    /// @dev The variable that controls the periods and whether the withdrawal is made for the security of the withdrawal periods.
    mapping(uint256 => bool) private withdrawControl;

    /// @dev Errors
    error mintFinishTrueError();
    error mintFinishFalseError();
    error mintStartTrueError();
    error mintStartFalseError();
    error withdrawTimeError(uint256 errorTime, uint256 blockTime);
    error maxSupplyError(uint256 totalCurrent, uint256 maxSupply);
    error insufficientBalance(uint256 msgValue, uint256 nftPrice);
    error maxMintError(uint256 msgBalance, uint256 perWallet);
    error withdrawClose();
    error repeatedWithdrawError();
    error noMoney();
    error nftOwnerError();
    error payError();

    /// @dev Events
    event startMintEvent(uint256 blockTime);
    event finishMintEvent(uint256 blokTime);
    event withdrawStartEvent(uint256 blockTime);
    event safeMintEvent(uint256 tokenId);
    event withdrawEvent(address msgSender, uint256 amount, uint256 period);
    event giveBackNFTEvent(uint256 tokenId, uint256 amount, uint256 period);

    /// @dev Modifiers: If Mint has started, continue with the code.
    modifier mintStartTrue() {
        if (!mintStart) revert mintStartTrueError();
        _;
    }

    /// @dev Modifiers: If Mint didn't start, continue with the code.
    modifier mintStartFalse() {
        if (mintStart) revert mintStartFalseError();
        _;
    }

    /// @dev Modifiers: If Mint is finished, continue with the code.
    modifier mintFinishTrue() {
        if (!mintFinish) revert mintFinishTrueError();
        _;
    }

    /// @dev If Mint is not finished, continue with the code.
    modifier mintFinishFalse() {
        if (mintFinish) revert mintFinishFalseError();
        _;
    }

    /// @dev Required constructor for ERC-721 parameters.
    constructor() ERC721("SIC Demo", "SICD") {}

    /// @dev The function that determines the url address where the NFTs will be found.
    function _baseURI() internal pure override returns (string memory) {
        return "https://localhost/";
    }

    /// @dev Function that allows us to read the variables MAX_SUPPLY, PRICE, PER_WALLET, PERIOD, WAIT_PERIOD_TIMESTAMP and PER_PERIOD_TIMESTAMP.
    function getConstantVariables()
        public
        pure
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        return (
            MAX_SUPPLY,
            PRICE,
            PER_WALLET,
            PERIOD,
            WAIT_PERIOD_TIMESTAMP,
            PER_PERIOD_TIMESTAMP
        );
    }

    /// @dev Function that allows us to read the stratTimestamp and perWithdraw variables.
    function getOtherVariables() public view returns (uint256, uint256) {
        return (startTimestamp, perWithdraw);
    }

    /// @dev Returns the total number of investors (Total number of NFTs).
    function getTotalInvestor() public view returns (uint256) {
        return _tokenIdCounter.current();
    }

    /// @dev Function that allows us to read the active period and total period of the contract.
    function getStatus() public view returns (uint256, uint256) {
        if (startTimestamp > 0) {
            return (getActivePeriod(), PERIOD);
        } else {
            return (0, PERIOD);
        }
    }

    /// @dev A function that calculates and reads the active period according to the timestamp data.
    function getActivePeriod() public view mintFinishTrue returns (uint256) {
        if (
            block.timestamp > (startTimestamp + (PER_PERIOD_TIMESTAMP * PERIOD))
        ) {
            return PERIOD;
        } else {
            uint256 elapsedTime = block.timestamp - startTimestamp;
            uint256 currentPeriod = elapsedTime / PER_PERIOD_TIMESTAMP;
            return currentPeriod + 1;
        }
    }

    /// @dev Mint launch function.
    function startMint() public onlyOwner mintStartFalse {
        mintStart = true;

        emit startMintEvent(block.timestamp);
    }

    /// @dev Mint manual finish function.
    function finishMint() public onlyOwner mintFinishFalse mintStartTrue {
        startTimestamp = block.timestamp;
        perWithdraw = address(this).balance / PERIOD;
        mintFinish = true;

        emit finishMintEvent(block.timestamp);
    }

    /// @dev Mint function.
    function safeMint() public payable mintFinishFalse mintStartTrue {
        if (_tokenIdCounter.current() > (MAX_SUPPLY + 1))
            revert maxSupplyError({
                totalCurrent: _tokenIdCounter.current(),
                maxSupply: MAX_SUPPLY
            });
        if (msg.value < PRICE)
            revert insufficientBalance({msgValue: msg.value, nftPrice: PRICE});
        if (ERC721.balanceOf(msg.sender) >= PER_WALLET)
            revert maxMintError({
                msgBalance: ERC721.balanceOf(msg.sender),
                perWallet: PER_WALLET
            });

        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();

        if (tokenId >= MAX_SUPPLY - 1) {
            startTimestamp = block.timestamp;
            mintFinish = true;
            perWithdraw = address(this).balance / PERIOD;
        }

        payable(address(this)).transfer(msg.value);
        _safeMint(msg.sender, tokenId);

        emit safeMintEvent(tokenId);
    }

    /// @dev The function that the contract creator must run in order to activate the withdrawal process.
    function withdrawStart() public onlyOwner {
        if (block.timestamp < (startTimestamp + WAIT_PERIOD_TIMESTAMP))
            revert withdrawTimeError({
                errorTime: (startTimestamp + WAIT_PERIOD_TIMESTAMP),
                blockTime: block.timestamp
            });

        withdrawCheck = true;

        emit withdrawStartEvent(block.timestamp);
    }

    /// @dev Withdrawal function by the originator from the contract.
    function withdraw() public payable onlyOwner mintFinishTrue {
        uint256 activePeriod = getActivePeriod();
        uint256 amount;

        if (!withdrawCheck) revert withdrawClose();
        if (withdrawControl[activePeriod]) revert repeatedWithdrawError();
        if (address(this).balance < 1) revert noMoney();

        if (address(this).balance > perWithdraw) {
            amount = perWithdraw;
        } else {
            amount = address(this).balance;
        }

        if (getActivePeriod() > PERIOD) {
            amount = address(this).balance;
        }

        withdrawControl[activePeriod] = true;
        address owner = owner();
        bool sent = payable(owner).send(amount);
        if (!sent) revert payError();

        emit withdrawEvent(msg.sender, amount, activePeriod);
    }

    /// @dev Function that allows investors (NFT owners) to return their NFTs and recover some of their investments if they do not trust the project.
    function giveBackNFT(uint256 _tokenId) public payable mintFinishTrue {
        if (ERC721.ownerOf(_tokenId) != msg.sender) revert nftOwnerError();

        uint256 contractBalance = address(this).balance;
        uint256 amount = contractBalance / _tokenIdCounter.current();

        _tokenIdCounter.decrement();
        ERC721._burn(_tokenId);
        bool sent = payable(msg.sender).send(amount);
        if (!sent) revert payError();

        emit giveBackNFTEvent(_tokenId, amount, getActivePeriod());
    }

    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}
}
