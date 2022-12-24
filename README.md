# Safe Investment Contract (SIC) <sub>`Safe investment collection contract.`</sub>


> WARNING : Some tests have been done on the contract. But it is still not completely safe. I continue to work on it. It will be finalized soon and tested on the Avalanche testnet.

### Summary
It is a contract created to protect and secure people's investments in projects. This contract, which has certain terms, aims to keep the funds safe. Thanks to this contract, the project owner will not be able to use all of the collected investment immediately. This contract, which has a withdrawal requirement for certain periods and a certain amount, aims to protect the investor.

### Problem
Many projects raise funds through tokens for investment. However, after these investments are received, many projects do not progress on the roadmap. In fact, the sole purpose of some projects is to collect the money and run away. However, many investors may not understand this situation. This adversely affects many projects, investors and future projects.

### Solution
This contract we have created brings the investor from a disadvantaged position to an advantageous position. It also pushes the project owners to develop the project. Because no one can access all the assets collected with this contract. The aim is that the assets collected under this contract benefit the progress of the project. For this reason, certain periods and certain amounts of assets are allowed to withdraw. And for the investor who sees that the project is not progressing, it will cause less damage and give up on their investment.

### Working Principle
It allows to create a certain amount of nft at the specified price when the contract is created. In addition, when the contract is created, the investor protection time and period time intervals are specified.

Then, the contract maker can start the mint process at any time and even if the collection sale has not ended, he can finish the mint process and start the contract work.

When the mint process ends, a start time is assigned and the money collected in the contract is divided by the period to determine the amount of coins that the project owner can withdraw per period.

No one can touch the assets during the investor protection period, and this period is actually a period created for investors to research the project and ask questions to the project owners to find out how healthy the project is.

During this period, if the investors do not trust the project, they can return the nfts and get their money back. If the nft is returned within the investor protection period, the same amount of coins is returned to the investor. However, if the periods progress, a refund is made by calculating the **_amount of refund = contract balance / nft amount_**. According to this calculation, if the Project does not show any improvement even in half of the period specified, it provides the opportunity to recover half of your investment.

After the investor protection period expires, the person who creates the contract activates the withdrawal process and can withdraw the amount per specified period to his wallet and start spending for the project. These withdrawals are made at the specified periods when the contract is created.

:arrow_right: Please let me know if I have any shortcomings or mistakes.


> Keep building for Blockchain. :heart:
