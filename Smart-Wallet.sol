//SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

contract smartWallet{

    address payable public owner;

    mapping(address => uint) public allowance;
    mapping(address => bool) public allowedToSend;

    mapping(address => bool) public guardians;

    address payable public nextOwner;
    uint guardiansResetCount;
    uint public constant confirmationsFromGuardiansForReset = 3;


    constructor(){
        owner = payable(msg.sender);
    }

    modifier onlyOwner {
        require(msg.sender == owner,"You Are not the Owner, Aborting Action");
        _;
    }

    function proposeNewOwner(address payable newOwner) public {
        require(guardians[msg.sender], "You are no guardian, aborting");
        if(nextOwner != newOwner) {
            nextOwner = newOwner;
            guardiansResetCount = 0;
        }

        guardiansResetCount++;

        if(guardiansResetCount >= confirmationsFromGuardiansForReset) {
            owner = nextOwner;
            nextOwner = payable(address(0));
        }
    }

    function setGaurdians(address _guardian, bool _isGuardian ) public onlyOwner{
        guardians[_guardian] = _isGuardian;
    }

    function setAllowance(address _from, uint _amount) public onlyOwner{ 
        allowance[_from] = _amount;
        allowedToSend[_from] = true;
    }

    function revokeSpending(address _who) public{
        allowedToSend[_who] = false;
    }

    function transfer(address payable _to, uint _amount, bytes memory payload) public returns (bytes memory) {
    require(_amount <= address(this).balance,"Contract does not have enough funds");
    if(msg.sender != owner){
        require(allowedToSend[msg.sender],"You are not allowed to send ant Transactions");
        require(allowance[msg.sender] >= _amount, "You cannot send more than you ae allowed to");
        allowance[msg.sender] -= _amount;
    }

    _to.transfer(_amount);

    (bool success, bytes memory returnData) = _to.call{value: _amount}(payload);
        require(success, "Transaction failed, aborting");
        return returnData;
    }
    


    receive() external payable {}
    

}