<!--
 * @Description: 
 * @Version: 1.0
 * @Autor: z.cejay@gmail.com
 * @Date: 2022-05-23 21:47:43
 * @LastEditors: cejay
 * @LastEditTime: 2022-05-24 16:33:46
-->
# contracts
合约

nvm use v14.19.3

remixd -s ./ --remix-ide https://remix.ethereum.org

存储：

node ./node_modules/sol-merger/dist/bin/sol-merger.js "./daoNFT/dataStorage.sol" ./build

node ./node_modules/sol-merger/dist/bin/sol-merger.js "./daoNFT/soulBoundMedal.sol" ./build

