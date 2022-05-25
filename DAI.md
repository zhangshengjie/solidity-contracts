# Decentralized Application interface
soulBoundMedal.sol 为DAO合约
soulBoundBridge.sol 为桥接工具

当前 soulBoundBridge.sol 的部署地址为：https://mumbai.polygonscan.com/address/0xabc1f5943425d1a1d14f1985cc351d00b655c6f2#code
当前 soulBoundMedal.sol 的部署地址为：https://mumbai.polygonscan.com/address/0xc49f649b69494205f9765757ee7260284d91ff3d#code

- 部署soulBoundMedal.sol时需要提供以下构造参数：
string memory _name,  NFT名字 部署后无法修改
string memory _symbol, NFT代号 部署后无法修改
string[] memory _medalname, 勋章名字数组
string[] memory _medaluri, 勋章图片url数组
address _daoBridgeAddress 桥接工具地址【固定地址】

- 更新一个勋章：
soulBoundMedal ->  function updateMedal( uint256 medalIndex, string calldata name, string calldata uri )其中medalIndex为勋章的索引

- 批量添加勋章：
soulBoundMedal -> function addMedals( string[] calldata medalsname, string[] calldata medalsuri ) 

- 请求勋章：
soulBoundMedal ->  function cliamRequest(uint8 medalIndex) ，其中medalIndex为勋章的索引


- 拒绝勋章请求：
soulBoundMedal ->  function cliamRejected(uint256 cliamId) ，其中cliamId为请求勋章索引

- 同意勋章请求：
soulBoundMedal ->  function cliamApproved(uint256 cliamId) ，其中cliamId为请求勋章索引

- 获取一个DAO合约的勋章以及发放统计 返回json
soulBoundBridge -> function listMedals( address _address, uint256 offset, uint256 limit ) _address为一个DAO合约的地址

- 获取一个DAO合约的勋章的请求记录总数
soulBoundBridge -> function countCliamRequest(address _dao) _dao为一个DAO合约的地址

- 根据请求索引获取一个DAO合约的勋章的请求详细记录，其中返回结构体中的转态码：0: rejected , 1: pending, 2: approved
soulBoundBridge -> function getCliamRequest(address _dao, uint256 _index)  _dao为一个DAO合约的地址

- 公开一个DAO（一个DAO合约只要有人请求过获取勋章 就会自动公开，但是也可以手工公开）
soulBoundBridge -> function register(address _address, address _dao) external _address为一个当前调用用户，_dao为一个DAO合约的地址

- 获取公开的DAO总数(一个DAO合约只要有人请求过获取勋章 就会自动公开)
soulBoundBridge -> function countDAO()

- 获取全部公开的DAO列表
soulBoundBridge -> function listDAO(uint256 offset,uint256 limit,uint256 medals_offset,uint256 medals_limit), offset+limit的最大值为公开的DAO总数，medals_offset一般为0就行，medals_limit表示获取的列表中每个DAO最大显示多少个勋章，如果为0则勋章数据返回空,但是DAO主体数据依然有

- 保存DAO的各种字符串信息 - 单个保存
soulBoundMedal -> function saveString(bytes4 k, string calldata v),其中k为key，v为value

- 保存DAO的各种字符串信息 - 批量保存
soulBoundMedal -> function saveStrings(bytes4[] calldata k, string[] calldata v),其中k为key数组，v为value数组

- 保存用户的各种字符串信息 - 单个保存
soulBoundBridge -> function saveString(bytes4 k, string calldata v),其中k为key，v为value

- 保存用户的各种字符串信息 - 批量保存
soulBoundBridge -> function saveStrings(bytes4[] calldata k, string[] calldata v),其中k为key数组，v为value数组

- 单个查询一个地址保存的字符串信息
soulBoundBridge -> function getString(address a, bytes4 k)，a为目标地址，k为key

- 批量查询一个地址保存的字符串信息
soulBoundBridge -> function getStrings(address a, bytes4[] k)，a为目标地址，k为key数组

- 批量查询多个地址的多个保存的字符串
soulBoundBridge -> function getStrings(address[] calldata a, bytes4[] calldata k) 返回一个二维数组

- 查询一个用户的所有NFT记录
soulBoundBridge -> function userDetail(address _address) _address为一个用户的地址，返回json




