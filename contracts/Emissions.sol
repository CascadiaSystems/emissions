// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

// import ERC20 transfer

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


interface ITWAP {
    function consult(address, uint) external view returns (uint);
}

contract Emissions is Ownable{
    // uint256 public PERIOD = 1 weeks;
    uint256 public PERIOD = 1 minutes;
    address any_asset;


    ITWAP public oracle_addy;
    address public treasury;
    IERC20 public cCC;
    uint256 public _tCCprice;

    event Withdrawal(uint amount, uint when);

    struct userData {
        uint256 currentLockedCcc;
        uint256 currentLockedAsset;
        uint256 totalBurntCcc;
        uint256 totalBurntAsset;
        uint256 awaitingWithdrawal;
        uint256 unlockTime;
    }

    struct anyAsset {
        bool stableToken;
        bool LPToken;
        bool OfficialAsset;
        IERC20 addy;
    }

    constructor(address _oracleAddy, address cCCAddy) payable {
        oracle_addy = ITWAP(_oracleAddy);
        cCC = IERC20(cCCAddy);
    }

    receive() external payable {}

    mapping(address => anyAsset) public anyAssets;
    mapping(address => userData) public users;

    function addAnyAsset(bool _stableToken, bool _LPToken, address _stableTokenAddress, bool _OfficialAsset) public onlyOwner {
        anyAssets[_stableTokenAddress].stableToken = _stableToken;
        anyAssets[_stableTokenAddress].LPToken = _LPToken;
        anyAssets[_stableTokenAddress].OfficialAsset = _OfficialAsset;
        anyAssets[_stableTokenAddress].addy = IERC20(_stableTokenAddress);
    }
    
    //logıc ekle
    function getCCoutput(address _anyAssetAddress, uint _anyAssetAmount) public view returns (uint256) {
        uint _tCCoutput = oracle_addy.consult(_anyAssetAddress, _anyAssetAmount);
        return (_tCCoutput);
    }  

    function withdraw(address anyAssetAddress) public {
        require(users[msg.sender].awaitingWithdrawal > 0 &&  block.timestamp > users[msg.sender].unlockTime , "You can't withdraw yet");
        uint256 _withdrawableAmount = users[msg.sender].awaitingWithdrawal;
        users[msg.sender].awaitingWithdrawal == 0;
        payable(msg.sender).transfer(_withdrawableAmount);
        require(anyAssets[anyAssetAddress].addy.transfer(treasury, users[msg.sender].currentLockedAsset));
        require(cCC.transfer(0x000000000000000000000000000000000000dEaD, users[msg.sender].currentLockedCcc));
        users[msg.sender].currentLockedAsset = 0;
        users[msg.sender].currentLockedCcc = 0;

        emit Withdrawal(address(this).balance, block.timestamp);
        //owner.transfer(users[msg.sender].awaitingWithdrawal);
    }

    function convert_cCCandAsset_toCC(address anyAssetAddress,uint256 anyAssetAmount) public{
        uint256 _amount = getCCoutput(anyAssetAddress,anyAssetAmount);
        uint256 cCCAmount = _amount/2; 

        
        require(anyAssets[anyAssetAddress].addy.transferFrom(msg.sender, address(this), anyAssetAmount));
        require(cCC.transferFrom(msg.sender, address(this), cCCAmount));

        users[msg.sender].currentLockedCcc += cCCAmount;
        users[msg.sender].currentLockedAsset += anyAssetAmount;
        users[msg.sender].totalBurntCcc += cCCAmount;
        users[msg.sender].totalBurntAsset += anyAssetAmount;
        users[msg.sender].awaitingWithdrawal += _amount;
        users[msg.sender].unlockTime = block.timestamp + PERIOD;
    }



    // function cancel_Convertion (address anyAssetAddress) external {
    //     require(users[msg.sender].awaitingWithdrawal > 0);
    //     users[msg.sender].awaitingWithdrawal ==  0;
    //     users[msg.sender].unlockTime == 0;
    //     users[msg.sender].currentLockedCcc == 0;
    //     users[msg.sender].currentLockedAsset == 0;
    //     require(anyAssets[anyAssetAddress].addy.transferFrom(msg.sender, address(this), anyAssetAmount));
    // }

    function updateTreasury(address _treasury) public onlyOwner {
        treasury = _treasury;
    }


}
