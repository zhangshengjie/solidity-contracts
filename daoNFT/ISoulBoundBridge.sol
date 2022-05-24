// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ISoulBoundBridge {
    //function registerDAO(address _address) external;

    function register(address _address, address _dao) external;

    /**
     * @dev list medals
     * @param offset the offset, from 0
     * @param limit the limit, minimum 1
     * @return string json string of query result
     */
    function listMedals(
        address _address,
        uint256 offset,
        uint256 limit
    ) external view returns (string memory);

    function countDAO() external view returns (uint256);

    function listDAO(
        uint256 offset,
        uint256 limit,
        uint256 medals_offset,
        uint256 medals_limit // no medals fetched if 0
    ) external view returns (string memory);
}
