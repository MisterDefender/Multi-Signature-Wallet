// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract MultisigWallet is Ownable {
    using SafeERC20 for IERC20;

    struct MultiSigOwnersDetails {
        uint256 timeOfIncusion;
        bool isTrusted;
    }

    struct Transactions {
        address to;
        address proposer;
        uint256 value;
        bool isConfirmed;
        bool sent;
        bool isERC20Payment;
        address tokenAddress;
        address[] signers; // this array should be full with minOwnerReqForSigning count for valid txn;
    }

    uint256 public immutable createdAt;
    uint256 public  minOwnerReqForSigning;
    uint256 public tokenCount;
    mapping(address => bool) public WhitelistedTokens;
    mapping (address => MultiSigOwnersDetails) owners;
    Transactions[] public transactions;

    constructor(uint256 _minOnwerReq) Ownable(msg.sender) {
        createdAt = block.number;
        minOwnerReqForSigning = _minOnwerReq;
    }
    
    function addMultiSigOwner(address _owner, bool _isTrusted) external  onlyOwner{
        require(owners[_owner].timeOfIncusion == 0, "Multisig owner already set");
        owners[_owner] = MultiSigOwnersDetails({timeOfIncusion: block.number, isTrusted: _isTrusted});
        
    }

    function addWhitelistedTokens(address token) external onlyOwner{
        require(address(token) != address(0), "Not allowed to add this token");
        WhitelistedTokens[token] = true;
        tokenCount+=1;
    }

    function isTokenWhitelisted(address token) public view returns (bool isWhitelisted){
        WhitelistedTokens[token] ? isWhitelisted = true : isWhitelisted;
    }

    function proposePayment(address _to, uint256 _amount, bool _isERC20Payment, address _tokenAddress) external returns(uint256 txnID) {
        
        Transactions storage proposedTxn = transactions[transactions.length - 1];
        proposedTxn.proposer = msg.sender;
        proposedTxn.to = _to;
        proposedTxn.value = _amount;
        proposedTxn.isERC20Payment = _isERC20Payment;
        if (_isERC20Payment) {
            require(_tokenAddress != address(0), "Not a vaild erc20 address");
            require(WhitelistedTokens[_tokenAddress], "Not a whitelisted token");
            proposedTxn.tokenAddress = _tokenAddress;
        }
        txnID = transactions.length;

    }

    function getProposedPayments() public view returns (uint256[] memory txIds ) {
        for (uint i = 0; i < transactions.length; i++) {
            if (!transactions[i].isConfirmed) {
                txIds[i] = i + 1;
            }
        }
    }

    function finaliseTxn(uint256 _txnId) external {
        require(transactions.length >= _txnId, "Transaction doesn't exists");
        require(msg.sender == transactions[_txnId-1].proposer, "Only txn proposer can finalise transaction");
        require(!transactions[_txnId-1].isConfirmed, "Transaction already finalised");
        require(_checkIfTxnIsValidatedInThresholdLimit(_txnId), "Transaction not validated by multi-sign signers");
        // Transactions storage txnToFinalise = transactions[_txnId-1];  
        transactions[_txnId-1].isConfirmed = true;
    }

    function sendFinalisedTxn(uint256 _txnId) external payable{
        require(msg.sender == transactions[_txnId-1].proposer, "Only txn finaliser can send transaction");
        require(transactions[_txnId-1].isConfirmed, "Transaction not finalised or signed yet");
        Transactions storage txnToFinalise = transactions[_txnId];
        if(txnToFinalise.isERC20Payment){
            bool transferSucess = IERC20(txnToFinalise.tokenAddress).transferFrom(txnToFinalise.proposer, txnToFinalise.to, txnToFinalise.value);
            require(transferSucess, "ERC20 transfer failed");
        }else {
            require(msg.value >= txnToFinalise.value, "Attached native amount is not sufficient");
            (bool sent,) = payable(txnToFinalise.to).call{value: msg.value}("");
            require(sent, "Failed to send Ether");
        }   
        txnToFinalise.sent = true;
    }

    


    function _isSignerIsValidOwner(address _signer) internal view returns (bool isValid){
        require(_signer != address(0), 'Invalid signer address(0)');
        if (owners[_signer].isTrusted) {
            isValid = true;
        } else {
            isValid = false;
        }
    }

    function _checkIfTxnIsValidatedInThresholdLimit(uint256 _txnId) internal view returns (bool _isValidated){
        transactions[_txnId-1].signers.length == minOwnerReqForSigning ? _isValidated = true : _isValidated;
    }

    function validatePaymentProposal(uint256 _txnID) external{
        require(transactions.length >= _txnID, "Transaction doesn't exists");
        require(transactions[_txnID-1].value > 0 , "Transaction not proposed yet");
        require(transactions[_txnID-1].to != address(0), "Transaction not propsed yet address zero");
        require(transactions[_txnID-1].isConfirmed == false, "Transaction already confirmed");
        require(_isSignerIsValidOwner(msg.sender), "To validate you must be the whitelisted signer");
        require(!_checkIfTxnIsValidatedInThresholdLimit(_txnID), "Threshold to sign txn is already reached");
        Transactions storage currentTxn = transactions[_txnID-1];
        currentTxn.signers.push(msg.sender);
    }


}
