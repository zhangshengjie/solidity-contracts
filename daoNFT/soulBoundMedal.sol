// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "./ISoulBoundMedal.sol";
import "./IDataStorage.sol";
import "./ISoulBoundBridge.sol";

contract SoulBoundMedal is ERC721, Ownable, ISoulBoundMedal {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;
    address public _daoBridge;
    string _baseUri = "";
    string[] private _medalnameArr;
    string[] private _medaluriArr;

    // Mapping from token ID to medal
    mapping(uint256 => uint8) private _medalMap;

    /**
     *  bytes32 :   address + medalIndex
     *  uint8 :   status of the cliam,  0: rejected , 1: pending, 2: approved
     */
    mapping(bytes32 => uint8) private _cliamStatus;

    CliamRequest[] private _cliamRequestList;

    ISoulBoundMedal.MedalPanel[] private _medalPanel;

    constructor(
        string memory _name,
        string memory _symbol,
        string[] memory _medalname,
        string[] memory _medaluri,
        address _daoBridgeAddress
    ) ERC721(_name, _symbol) {
        _medalnameArr = _medalname;
        _medaluriArr = _medaluri;
        _daoBridge = _daoBridgeAddress;
        for (uint256 i = 0; i < _medalnameArr.length; i++) {
            _medalPanel.push(MedalPanel(0, 0, 0, block.timestamp));
        }
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseUri;
    }

    function setBaseURI(string memory baseUri) public onlyOwner {
        _baseUri = baseUri;
    }

    /**
     * @dev if the token is soulbound
     * @return true if the token is soulbound
     */
    function soulbound() public pure override returns (bool) {
        return true;
    }

    function setDAOBridge(address _daoBridgeAddress) public onlyOwner {
        _daoBridge = _daoBridgeAddress;
    }

    modifier DataStorageCheck() {
        require(_daoBridge != address(0), "dataStorage is not set");
        _;
    }

    /**
     * use global data storage to save the data
     */
    function saveString(bytes4 k, string calldata v)
        public
        onlyOwner
        DataStorageCheck
    {
        IDataStorage dataStorageInstance = IDataStorage(_daoBridge);
        dataStorageInstance.saveString(k, v);
    }

    /**
     * use global data storage to save the data
     */
    function getString(bytes4 k)
        public
        view
        DataStorageCheck
        returns (string memory)
    {
        IDataStorage dataStorageInstance = IDataStorage(_daoBridge);
        return dataStorageInstance.getString(address(this), k);
    }

    /**
     * use global data storage to save the data
     */
    function saveStrings(bytes4[] calldata k, string[] calldata v)
        public
        onlyOwner
        DataStorageCheck
    {
        IDataStorage dataStorageInstance = IDataStorage(_daoBridge);
        return dataStorageInstance.saveStrings(k, v);
    }

    /**
     * use global data storage to save the data
     */
    function getStrings(bytes4[] calldata k)
        public
        view
        DataStorageCheck
        returns (string[] memory)
    {
        IDataStorage dataStorageInstance = IDataStorage(_daoBridge);
        return dataStorageInstance.getStrings(address(this), k);
    }

    /**
     * @dev Add medals to current DAO
     * @param medalsname array of medal name
     * @param medalsuri array of medal uri
     */
    function addMedals(
        string[] calldata medalsname,
        string[] calldata medalsuri
    ) public override onlyOwner {
        require(medalsname.length > 0 && medalsname.length == medalsuri.length);
        for (uint256 i = 0; i < medalsname.length; i++) {
            _medalnameArr.push(medalsname[i]);
            _medaluriArr.push(medalsuri[i]);
            _medalPanel.push(MedalPanel(0, 0, 0, block.timestamp));
        }
    }

    /**
     * @dev get medals
     * @return array of medals
     */
    function getMedals()
        public
        view
        override
        returns (
            string[] memory,
            string[] memory,
            ISoulBoundMedal.MedalPanel[] memory
        )
    {
        return (_medalnameArr, _medaluriArr, _medalPanel);
    }

    /**
     * @dev get medalIndex by tokenid
     */
    function getMedalIndexByTokenid(uint256 tokenid)
        public
        view
        override
        returns (uint8)
    {
        return _medalMap[tokenid];
    }

    /**
     * @dev get cliam status by key
     */
    function getCliamStatusByBytes32Key(bytes32 key)
        public
        view
        override
        returns (uint8)
    {
        return _cliamStatus[key];
    }

    function getCliamRequestSize() public view override returns (uint256) {
        return _cliamRequestList.length;
    }

    function getCliamRequest(uint256 _index)
        public
        view
        override
        returns (CliamRequest memory)
    {
        require(_index < _cliamRequestList.length);
        return _cliamRequestList[_index];
    }

    /**
     * @dev update medal by index
     * @param index index of medal
     * @param name new name of medal
     * @param uri new uri of medal
     */
    function updateMedal(
        uint256 index,
        string calldata name,
        string calldata uri
    ) public override onlyOwner {
        require(index < _medalnameArr.length);
        _medalnameArr[index] = name;
        _medaluriArr[index] = uri;
    }

    /**
     * @dev  Approved cliam
     * @param cliamId the index of the cliam id
     * Emits a {Transfer} event.
     */
    function cliamApproved(uint256 cliamId) public override onlyOwner {
        require(cliamId < _cliamRequestList.length);
        CliamRequest memory request = _cliamRequestList[cliamId];
        bytes32 k = keccak256(
            abi.encodePacked(request._address, request._medalIndex)
        );
        uint8 cliamStatus = _cliamStatus[k];
        require(cliamStatus == 1);
        _cliamStatus[k] = 2;
        _cliamRequestList[cliamId]._status = 2;
        unchecked {
            _medalPanel[request._medalIndex]._approved++;
        }
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();
        _medalMap[tokenId] = request._medalIndex;
        _mint(request._address, tokenId);
    }

    /**
     * @dev  Rejected cliam
     * @param cliamId the index of the cliam id
     */
    function cliamRejected(uint256 cliamId) public override onlyOwner {
        require(cliamId < _cliamRequestList.length);
        CliamRequest memory request = _cliamRequestList[cliamId];
        bytes32 k = keccak256(
            abi.encodePacked(request._address, request._medalIndex)
        );
        uint8 cliamStatus = _cliamStatus[k];
        require(cliamStatus == 1);
        _cliamStatus[k] = 0;
        _cliamRequestList[cliamId]._status = 0;
        unchecked {
            _medalPanel[request._medalIndex]._rejected++;
        }
    }

    /**
     * @dev Users apply for mint medal
     * @param medalIndex the index of the medal
     */
    function cliamRequest(uint8 medalIndex) public override {
        require(medalIndex < _medalnameArr.length);
        bytes32 k = keccak256(abi.encodePacked(msg.sender, medalIndex));
        uint8 cliamStatus = _cliamStatus[k];
        if (cliamStatus != 2) {
            _cliamStatus[k] = 1;
            _cliamRequestList.push(
                CliamRequest(msg.sender, medalIndex, block.timestamp, 1)
            );
            unchecked {
                _medalPanel[medalIndex]._request++;
            }
            ISoulBoundBridge soulBoundBridge = ISoulBoundBridge(_daoBridge);
            soulBoundBridge.register(msg.sender, address(this));
        } else {
            revert("already approved");
        }
    }

    function _cliamRequest(bytes32 k, uint8 medalIndex) private {}

    /**
     * @dev  RFC 3986 compliant URL:base64://{json encoded with base64}
     * json {"name":"base64(medal name)","image":"base64(medal uri)"}
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        string memory baseURI = _baseURI();
        string memory medalName = _medalnameArr[_medalMap[tokenId]];
        string memory medalURI = string(
            abi.encodePacked(baseURI, _medaluriArr[_medalMap[tokenId]])
        );
        string memory json = string(
            abi.encodePacked(
                "base64://",
                Base64.encode(
                    abi.encodePacked(
                        '{"name":"',
                        Base64.encode(bytes(medalName)),
                        '","image":"',
                        Base64.encode(bytes(medalURI)),
                        '"}'
                    )
                )
            )
        );
        return json;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(ISoulBound).interfaceId ||
            interfaceId == type(ISoulBoundMedal).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    modifier SoulBoundToken() {
        require(soulbound() == false, "SoulBound token cannot be transferred.");
        _;
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(IERC721, ERC721) SoulBoundToken {}

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(IERC721, ERC721) SoulBoundToken {}

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public override(IERC721, ERC721) SoulBoundToken {}
}
