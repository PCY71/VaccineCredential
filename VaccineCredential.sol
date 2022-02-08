// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.10;

abstract contract OwnerHelper {
    address private owner;

    event OwnerTransferPropose(address indexed _from, address indexed _to);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only Owner can execute this function");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function transferOwnership(address _to) public onlyOwner {
        require(_to != owner, "both addresses are same");
        require(_to != address(0x0), "invalid address");
        owner = _to;
        emit OwnerTransferPropose(owner, _to);
    }
}

abstract contract IssuerHelper is OwnerHelper {
    mapping(address => bool) public issuers;

    event AddIssuer(address indexed _issuer);
    event DelIssuer(address indexed _issuer);

    modifier onlyIssuer() {
        require(
            isIssuer(msg.sender) == true,
            "Only Issuer can execute this function"
        );
        _;
    }

    constructor() {
        issuers[msg.sender] = true;
    }

    function isIssuer(address _addr) public view returns (bool) {
        return issuers[_addr];
    }

    function addIssuer(address _addr) public onlyOwner returns (bool) {
        require(issuers[_addr] != true);
        issuers[_addr] = true;
        emit AddIssuer(_addr);
        return true;
    }

    function delIssuer(address _addr) public onlyOwner returns (bool) {
        require(issuers[_addr] != false);
        issuers[_addr] = false;
        emit DelIssuer(_addr);
        return true;
    }
}

contract VaccineCredential is IssuerHelper {
    uint256 public idCount;
    mapping(uint8 => string) private vaccineEnum;
    mapping(uint8 => string) private statusEnum;

    struct Credential {
        uint256 id; // index
        address[] issuer; // 접종 기관의 주소
        uint8 statusType; // 현재 접종 상태
        string[] value; // 암호화 된 정보가 JSON 형태로 저장
        uint256 createDate; // Credential의 생성일자
        uint8 vaccineNum; // 현재 백신 차수
        uint8[] vaccineType; // 백신 type
        uint256[] shotDate; // 접종 일자
        string[] vaccineCode; // 백신 code
    }

    mapping(address => Credential) private credentials;

    constructor() {
        idCount = 1;
        vaccineEnum[0] = "JS"; // Janssen
        vaccineEnum[1] = "MDN"; // Moderna
        vaccineEnum[2] = "PFZ"; // Pfizer
        vaccineEnum[3] = "AZ"; // AstraZeneca

        statusEnum[0] = "not_vaccinated"; // 미접종
        statusEnum[1] = "valid"; // 유효한 접종자
        statusEnum[2] = "expired"; // 만료된 접종자
    }

    function claimCredential(
        address _humanAddress,
        uint8 _vaccineNum,
        uint8 _vaccineType,
        uint8 _statusType,
        string calldata _value,
        string calldata _vaccineCode
    ) public onlyIssuer returns (bool) {
        Credential storage credential = credentials[_humanAddress];
        require(_vaccineNum == 1);
        credential.id = idCount;
        credential.issuer.push(msg.sender);
        credential.vaccineNum = _vaccineNum;
        credential.statusType = _statusType;
        credential.value.push(_value);
        credential.vaccineType.push(_vaccineType);
        credential.vaccineCode.push(_vaccineCode);
        credential.shotDate.push(block.timestamp);
        credential.createDate = block.timestamp;
        idCount += 1;

        return true;
    }

    function updateCredential(
        address _humanAddress,
        uint8 _vaccineNum,
        uint8 _vaccineType,
        uint8 _statusType,
        string calldata _value,
        string calldata _vaccineCode
    ) public onlyIssuer returns (bool) {
        Credential storage credential = credentials[_humanAddress];
        require(_vaccineNum == credential.vaccineNum + 1);
        credential.issuer.push(msg.sender);
        credential.vaccineNum = _vaccineNum;
        credential.statusType = _statusType;
        credential.value.push(_value);
        credential.vaccineType.push(_vaccineType);
        credential.vaccineCode.push(_vaccineCode);
        credential.shotDate.push(block.timestamp);

        return true;
    }

    function getCredential(address _humanAddress)
        public
        view
        returns (Credential memory)
    {
        Credential storage credential = credentials[_humanAddress];
        require(credential.id != 0);
        return (credentials[_humanAddress]);
    }

    function addVaccineType(uint8 _type, string calldata _value)
        public
        onlyIssuer
        returns (bool)
    {
        require(
            bytes(vaccineEnum[_type]).length == 0,
            "That code is already exists"
        );
        vaccineEnum[_type] = _value;
        return true;
    }

    function getVaccineType(uint8 _type) public view returns (string memory) {
        return vaccineEnum[_type];
    }

    function addStatusType(uint8 _type, string calldata _value)
        public
        onlyIssuer
        returns (bool)
    {
        require(bytes(statusEnum[_type]).length == 0);
        statusEnum[_type] = _value;
        return true;
    }

    function delStatusType(uint8 _type) public onlyIssuer returns (bool) {
        require(bytes(statusEnum[_type]).length != 0);
        statusEnum[_type] = "";
        return true;
    }

    function getStatusType(uint8 _type) public view returns (string memory) {
        return statusEnum[_type];
    }

    function changeStatus(address _humanAddress, uint8 _type)
        public
        onlyIssuer
        returns (bool)
    {
        require(credentials[_humanAddress].id != 0);
        require(bytes(statusEnum[_type]).length != 0);
        credentials[_humanAddress].statusType = _type;
        return true;
    }
}
