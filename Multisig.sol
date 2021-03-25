pragma solidity 0.8.0;

contract Multisig{

    address [] public Owner;
    mapping(address => bool) IsOwner;
    struct Transaction{

        address to;
        uint value;
        uint no_of_confirmation;
        bool executed;
        bytes data;

    }
    // txid --> msg.sender --> bool
    mapping(uint  => mapping(address => bool)) Isconfirmed;
    Transaction []  public transactions;
    uint public No_Of_confirmation_Required;

    event deposit(address from, uint value, uint balance);
    event SubmittedTransaction(address owner, uint _txId, uint value, address to, bytes  data );
    event TransactionConfirmed(uint _txId, address owner);
    event TransactionExecuted(uint _txId, address owner);
    event TransactionRevoked(uint _txId,  address owner);

    modifier onlyOwner{

        require(IsOwner[msg.sender] == true, "Not an Owner");
        _;
    }

    modifier txExist(uint _txId){
        require(_txId < transactions.length, "transaction does not exist");
        _;
    }

    modifier notExecuted(uint _txId){
         require(!transactions[_txId].executed, " its already executed");
        _;
        
    }

    modifier notConfirmed(uint _txId){
        require(Isconfirmed[_txId][msg.sender] == false, "already confrmed the transaction");
        _;
    }
 
    constructor (address [] memory _owner, uint _No_Of_confirmation_Required) public{

         require(_owner.length > 0 , "invalid no of Owners");
         require(_No_Of_confirmation_Required > 0 , "invalid no of confirmation");
         require(_No_Of_confirmation_Required <= _owner.length, "invalid no of confirmation");
         
         

         for(uint i = 0; i < _owner.length; i++){
             address owner = _owner[i];
             require(owner != 0x0000000000000000000000000000000000000000, "invalid address");
             require(!IsOwner[owner], "owner not unique");

            IsOwner[owner] = true;
             Owner.push(owner);
             
             

         }

         No_Of_confirmation_Required += _No_Of_confirmation_Required;
    }

    fallback() payable external{

        emit deposit(msg.sender, msg.value, address(this).balance);
    }

    // owner submit the transaction to get confirm
    
    function submitTransaction(address _to, uint _value, bytes memory _data) onlyOwner public{
      require(_to != 0x0000000000000000000000000000000000000000, "invalid address");
      
      uint _txId = transactions.length;

      Transaction memory transaction;
        transaction.to = _to;
        transaction.value =  _value;
          transaction.data =  _data;
         transaction.executed =  false;
          transaction.no_of_confirmation =  0;
          
        transactions.push(transaction);
          
      emit SubmittedTransaction(msg.sender, _txId, _value, _to, _data);
         

    }
    
    // confirm the transaction sent by other owner
    function confirm(uint _txId) onlyOwner txExist(_txId) notConfirmed(_txId) notExecuted(_txId) public{
         Transaction storage transaction = transactions[_txId];
         Isconfirmed[_txId][msg.sender] = true;
         transaction.no_of_confirmation += 1;

         emit TransactionConfirmed(_txId, msg.sender);

    }

    // execute the transaction when it confirmation reaches to required confirmation count

    function execute(uint _txId) onlyOwner txExist(_txId) notExecuted(_txId) public{

        Transaction storage transaction = transactions[_txId];
        require(transaction.no_of_confirmation >= No_Of_confirmation_Required, " no of confirmation is less");
        transaction.executed = true;
        uint amount = transaction.value;
        (bool _success, )= transaction.to.call{value : amount}(transaction.data);
        require(_success, "transaction failed");

        emit TransactionExecuted(_txId, msg.sender);
    }


    // revoke the confirmation

     function Revoke(uint  _txId) onlyOwner txExist(_txId) notExecuted(_txId) public{
          
          Transaction storage transaction = transactions[_txId];
          require(Isconfirmed[_txId][msg.sender], " not confirmed the transaction");
          Isconfirmed[_txId][msg.sender] = false;
          transaction.no_of_confirmation -= 1;

          emit TransactionRevoked(_txId, msg.sender);
       }


    function getOwners() public view returns (address[] memory) {
        return Owner;
    }

    function getTransactionCount() public view returns (uint) {
        return transactions.length;
    }


    function getTransaction(uint _txIndex) public view
        returns (address to, uint value, bytes memory data, bool executed, uint numConfirmations)
    {
        Transaction storage transaction = transactions[_txIndex];

        return (
            transaction.to,
            transaction.value,
            transaction.data,
            transaction.executed,
            transaction.no_of_confirmation
        );
    }

    function isConfirmed(uint _txIndex, address _owner) public view returns (bool)
    {
        Transaction storage transaction = transactions[_txIndex];

        return Isconfirmed[_txIndex][msg.sender];
    }
    
    // function for sending ether to contract for testing  in remix
    
       function Deposit(uint amount) external payable{}
       
    
    /// ["0x5B38Da6a701c568545dCfcB03FcB875f56beddC4", "0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2", "0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db"]
}
