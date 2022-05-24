// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./ISoulBoundMedal.sol";
import "./IDataStorage.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "./ISoulBoundBridge.sol";

contract SoulBoundBridge is IDataStorage, ISoulBoundBridge {
    address[] public storageEnumerableUserArr;

    mapping(address => uint256[]) public storageEnumerableUserMap;
    mapping(bytes32 => uint8) public userDAOMapping;
    mapping(address => uint256) public storageEnumerableDAOMap;
    address[] public storageEnumerableDAOArr;

    mapping(address => mapping(bytes4 => string)) public storageStrings;

    constructor() {}

    function saveString(bytes4 k, string calldata v) public override {
        storageStrings[msg.sender][k] = v;
    }

    function getString(address a, bytes4 k)
        public
        view
        override
        returns (string memory)
    {
        return storageStrings[a][k];
    }

    function saveStrings(bytes4[] calldata k, string[] calldata v)
        public
        override
    {
        for (uint256 i = 0; i < k.length; i++) {
            storageStrings[msg.sender][k[i]] = v[i];
        }
    }

    function getStrings(address a, bytes4[] calldata k)
        public
        view
        override
        returns (string[] memory)
    {
        string[] memory result = new string[](k.length);
        for (uint256 i = 0; i < k.length; i++) {
            result[i] = storageStrings[a][k[i]];
        }
        return result;
    }

    modifier onlySoulBoundMedalAddress(address _soulBoundMedalAddress) {
        require(
            _soulBoundMedalAddress.code.length > 0,
            "given address is not a valid contract"
        );
        require(
            IERC165(_soulBoundMedalAddress).supportsInterface(
                type(ISoulBoundMedal).interfaceId
            ),
            "given address is not a valid soul bound medal contract"
        );

        _;
    }

    function register(address _address, address _dao) public override {
        if (storageEnumerableDAOMap[_dao] == 0) {
            require(
                _dao.code.length > 0,
                "given address is not a valid contract"
            );
            require(
                IERC165(_dao).supportsInterface(
                    type(ISoulBoundMedal).interfaceId
                ),
                "given address is not a valid soul bound medal contract"
            );
            storageEnumerableDAOArr.push(_dao);
            storageEnumerableDAOMap[_dao] = storageEnumerableDAOArr.length;
        }
        bytes32 userDAOMappingKey = keccak256(abi.encodePacked(_address, _dao));
        if (userDAOMapping[userDAOMappingKey] == 0) {
            userDAOMapping[userDAOMappingKey] = 1;
            if (storageEnumerableUserMap[_address].length == 0) {
                storageEnumerableUserArr.push(_address);
            }
            storageEnumerableUserMap[_address].push(
                storageEnumerableDAOMap[_dao]
            );
        }
    }

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
    )
        public
        view
        override
        onlySoulBoundMedalAddress(_address)
        returns (string memory)
    {
        ISoulBoundMedal medalContract = ISoulBoundMedal(_address);
        /*
        {"total":1,"medals":[
                {
                    "index":0,
                    "name":"base64 string",
                    "uri":"base64 string",
                    "request":0,
                    "approved":0,
                    "rejected":0,
                    "genesis":1539098983
                }
            
            ]
        }
         */
        string[] memory _medalnameArr;
        string[] memory _medaluriArr;
        ISoulBoundMedal.MedalPanel[] memory _medalPanel;
        (_medalnameArr, _medaluriArr, _medalPanel) = medalContract.getMedals();
        string memory result = '{"total":';
        result = string(
            abi.encodePacked(
                result,
                Strings.toString(_medalnameArr.length),
                ',"medals":['
            )
        );
        unchecked {
            for (uint256 i = offset; i < offset + limit; i++) {
                if (i >= _medalnameArr.length) {
                    break;
                }
                if (i > offset) {
                    result = string(abi.encodePacked(result, ","));
                }
                result = string(
                    abi.encodePacked(
                        result,
                        "{",
                        '"index":',
                        Strings.toString(i),
                        ',"name":"',
                        Base64.encode(bytes(_medalnameArr[i])),
                        '","uri":"',
                        Base64.encode(bytes(_medaluriArr[i])),
                        '","request":',
                        Strings.toString(_medalPanel[i]._request),
                        ',"approved":',
                        Strings.toString(_medalPanel[i]._approved),
                        ',"rejected":',
                        Strings.toString(_medalPanel[i]._rejected),
                        ',"genesis":',
                        Strings.toString(_medalPanel[i]._genesis),
                        "}"
                    )
                );
            }
        }
        result = string(abi.encodePacked(result, "]}"));

        return result;
    }

    function countDAO() public view override returns (uint256) {
        return storageEnumerableDAOArr.length;
    }

    function listDAO(
        uint256 offset,
        uint256 limit,
        uint256 medals_offset,
        uint256 medals_limit // no medals fetched if 0
    ) public view override returns (string memory) {
        /* 
        {
           "address": [
                            '0x1',
                            '0x2'
                        ],
            "medals": [
                        {"total":1,"medals":[
                                                    {
                                                        "index":0,
                                                        "name":"base64 string",
                                                        "uri":"base64 string",
                                                        "request":0,
                                                        "approved":0,
                                                        "rejected":0,
                                                        "genesis":1539098983
                                                    }
                                            ]
                        }
                    ]
        } 
         */
        string memory result_address = "[";
        string memory result_medals = "[";
        for (uint256 i = offset; i < offset + limit; i++) {
            if (i >= storageEnumerableDAOArr.length) {
                break;
            }
            if (i > offset) {
                result_address = string(abi.encodePacked(result_address, ","));
            }
            result_address = string(
                abi.encodePacked(
                    result_address,
                    '"',
                    Strings.toHexString(
                        uint256(uint160(storageEnumerableDAOArr[i]))
                    ),
                    '"'
                )
            );
            if (medals_limit > 0) {
                if (i > offset) {
                    result_medals = string(
                        abi.encodePacked(result_medals, ",")
                    );
                }
                result_medals = string(
                    abi.encodePacked(
                        result_medals,
                        listMedals(
                            storageEnumerableDAOArr[i],
                            medals_offset,
                            medals_limit
                        )
                    )
                );
            }
        }
        result_address = string(abi.encodePacked(result_address, "]"));
        result_medals = string(abi.encodePacked(result_medals, "]"));
        return
            string(
                abi.encodePacked(
                    '{"address":',
                    result_address,
                    ',"medals":',
                    result_medals,
                    "}"
                )
            );
    }
}