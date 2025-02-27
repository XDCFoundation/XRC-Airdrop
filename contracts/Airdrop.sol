pragma solidity ^0.8.10;
// SPDX-License-Identifier: MIT
import "./XRC20.sol";
//interface for external contracts to execute
interface Airdrop_interface{
    function changeOwner(address newOwner) external;
    function DeployAirDrop(bool _status)external returns(bool);
    function getOwner() external view returns(address);
    function AddUser(address _User,uint _amount)external returns(bool);
    function RemoveUser(uint _userCount,bool _exist)external returns(string memory);
    function ViewUsers(uint _userCount) external view returns(address,uint,bool);
    function RedeemAirdrop(uint i)external returns(bool);
    function viewBalanceInContract()external view returns(uint);
}

contract Airdrop is Airdrop_interface{
    //contract variables
    address private owner;
    uint public airdropCount=0;

    uint public TotalAlocated=0;
    bool public AirDropStatus;
    uint public leftToBeAllocated;
    IERC20 public XRC_Contract;
    
    event OwnerSet(address indexed oldOwner, address indexed newOwner);
    // check owner of airdrop contract
    modifier isOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }
    //executes after airdrop
    modifier preAirdrop{
        require(AirDropStatus == false, "Airdrop status must be false");
        _;
    }
    //executes before airdrop
    modifier postAirdrop{
        require(AirDropStatus == true,"Airdrop status must be true");
        _;
    }
    //struct mapping int
    mapping(uint => AirDropDB) userAirdrop;
    struct AirDropDB{
        address User;
        uint amount;
        bool exist;
    }
    constructor(){
        owner = msg.sender;
        emit OwnerSet(address(0), owner);
    }
    //change owner
    function changeOwner(address newOwner) public isOwner preAirdrop {
        emit OwnerSet(owner, newOwner);
        owner = newOwner;
    }
    //get owner
    function getOwner() external view returns(address) {
        return owner;
    }
    //Add User to contract
    function AddUser(address _User,uint _amount)public isOwner preAirdrop returns(bool){
        leftToBeAllocated = viewBalanceInContract() - TotalAlocated;
        if(leftToBeAllocated >0 && _amount <= leftToBeAllocated){
            userAirdrop[airdropCount] = AirDropDB(_User,_amount,true);
            airdropCount++;
            TotalAlocated = TotalAlocated + _amount;    
            leftToBeAllocated = viewBalanceInContract() - TotalAlocated;        
            return true;
        } else {
            return false;
        }
    }
    //Edit Airdrop users
    function RemoveUser(uint _userCount,bool _exist)public isOwner preAirdrop returns(string memory){
        userAirdrop[_userCount].exist = _exist;
        if(_exist == false){
            TotalAlocated = TotalAlocated - userAirdrop[_userCount].amount;
            leftToBeAllocated = viewBalanceInContract() - TotalAlocated;
            userAirdrop[_userCount].amount=0;
            return "User removed";
        } else{
            return "User not removed";
        }
    }
    //view accounts with pledged amounts
    function ViewUsers(uint _userCount) public view returns(address,uint,bool){
        return (userAirdrop[_userCount].User,userAirdrop[_userCount].amount,userAirdrop[_userCount].exist);
    }
    //Set contract 
    function Register_XRC_Contract(IERC20 _Contract) public isOwner preAirdrop returns(bool){
        XRC_Contract = _Contract;
        return true;
    }
    //Deploy Airdrop
    function DeployAirDrop(bool _status)public isOwner preAirdrop returns(bool){
        AirDropStatus = _status;
        XRC_Contract.transfer(msg.sender,leftToBeAllocated);
        leftToBeAllocated =0;
        return AirDropStatus;
    }
    //Users who were air dropped tokens can have them redeemed
    // i has to be 0 for a full query
    function RedeemAirdrop(uint i)public postAirdrop returns(bool){
        //add continuous execution for loop
        for(i;i<=airdropCount;i++){
            if(userAirdrop[i].User == msg.sender){
                XRC_Contract.transfer(owner,userAirdrop[i].amount);
                return true;                
            }
        }
        return false;
    }
    //view Total totens to be airdropped
    function viewBalanceInContract()public view isOwner returns(uint){
        uint tokensInContract = XRC_Contract.balanceOf(address(this)); // this shows the balance of the XRC20 token in the Airdrop contract
        return tokensInContract;
    }
}


