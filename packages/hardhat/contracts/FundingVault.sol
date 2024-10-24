//SPDX-License-Identifier: MIT

/**
 * Layout of the contract
 * version
 * imports
 * errors
 * interfaces, libraries, and contracts
 * type declarations
 * state variables
 * events
 * modifiers
 * functions
 *
 * layout of functions
 * constructor
 * receive function
 * fallback function
 * external functions
 * public functions
 * internal functions
 * private functions
 * view functions
 * pure functions
 * getters
 */
 pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title FundingVault
 * @author Muhammad Zain Nasir
 * @notice  A contract that allows users to deposit funds and receive participation tokens in return box creator can call WithdrawFunds if there enough funds collected
 */
contract FundingVault{

 // Errors //
    error FundingVault__AmountCannotBeZero(); //
    error FundingVault__minFundingAmountReached();
    error FundingVault__minFundingAmountNotReached();
    error FundingVault__deadlineNotPassed(); //
    error FundingVault__deadlinePassed(); 
    error FundingVault__NotEnoughTokens(); //
    error FundingVault__noTokenBalance();
    error FundingVault__fundsWithdrawn();
    error FundingVault__TokenTransferFailed();
    error FundingVault__EthTransferFailed();
    error FundingVault__EthTransferToDeveloperFailed();
    error FundingVault__EthTransferToWithdrawlFailed();


    // State Variables //
    IERC20 private immutable participationToken;
    uint256 private participationTokenAmount;
    uint256 private blockLimit;
    uint256 private minFundingAmount; //The minimum amount of ETH required in the contract to enable withdrawal.
    uint256 private exchangeRate; //The exchange rate of ERG per token
    address private withdrawlAddress;
    address private developerFeeAddress; //develper address
    uint256 private developerFeePercentage; 
    string  private projectURL;
    bool private fundsWithdrawn;


    // Events //
    event TokensPurchased(address indexed from, uint256 indexed amount);
    event Refund(address indexed user, uint256 indexed amount);
    event FundsWithdrawn(address indexed user, uint256 amount);



    modifier deadlinePassed() {
        if (block.number < blockLimit) {
            revert FundingVault__deadlineNotPassed();
        }
        _;
    }
    modifier deadlineNotPassed() {
        if (block.number > blockLimit) {
            revert FundingVault__deadlinePassed();
        }
        _;
    }


    // Functions //

     /**
     * @param _participationToken The token that will be used as participation token to incentivise donators
     * @param _participationTokenAmount Theinitial  participation token amount which will be in fundingVault
     * @param _minFundingAmount The minimum amount required to make withdraw of funds possible
     * @param _blockLimit The date (block height) limit until which withdrawal or after which refund is allowed.
     * @param _withdrawlAddress The address for withdrawl of funds
     * @param _developerFeeAddress the address for the developer fee
     * @param _developerFeePercentage the percentage fee for the developer.
     * @param _projectURL A link or hash containing the project's information (e.g., GitHub repository).
     */
    
     constructor(
        address _participationToken,
        uint256 _participationTokenAmount,  
        uint256 _minFundingAmount,
        uint256 _blockLimit,
        uint256 _exchangeRate,
        address _withdrawlAddress,
        address _developerFeeAddress, //develper address
        uint256 _developerFeePercentage, 
        string memory _projectURL
    ) {
        
        participationToken  = IERC20(_participationToken);
        participationTokenAmount  = _participationTokenAmount ;
        minFundingAmount = _minFundingAmount;
        blockLimit = _blockLimit;
        exchangeRate = _exchangeRate;
        withdrawlAddress = _withdrawlAddress;
        developerFeeAddress =  _developerFeeAddress;
        developerFeePercentage = _developerFeePercentage;
        projectURL = _projectURL;
    }

    
    /**
     * @dev Allows users to deposit Ether and purchase participation tokens based on exchange rate
     */
    function purchaseTokens() external payable {
        if (msg.value == 0){
            revert FundingVault__AmountCannotBeZero();
        }

        
        uint256 tokenAmount = msg.value * exchangeRate;

        if (participationToken.balanceOf(address(this)) < tokenAmount)
        {
            revert FundingVault__NotEnoughTokens();
        }

        
        bool tokenTransferSuccess = participationToken.transfer(msg.sender, tokenAmount);
        if (!tokenTransferSuccess){
            revert FundingVault__TokenTransferFailed();
        }
        
        emit TokensPurchased(msg.sender, tokenAmount);
    }

    /**
     * @dev Allows users to exchange tokens for Eth (at exchange rate) if and only if the deadline has passed and the minimum number of tokens has not been sold.
     */

    function refundTokens() external payable deadlineNotPassed{

        if(address(this).balance >= minFundingAmount){
        revert FundingVault__minFundingAmountReached();
        }
        uint tokensHeld = participationToken.balanceOf(msg.sender);
        if (tokensHeld == 0){
        revert FundingVault__noTokenBalance();
        }

        uint256 refundAmount = tokensHeld * exchangeRate;

       
        bool tokenTransferSuccess = participationToken.transferFrom(msg.sender, address(this), tokensHeld);
        if (!tokenTransferSuccess){
            revert FundingVault__TokenTransferFailed();
        }
       
        (bool ethTransferSuccess, ) = payable(msg.sender).call{value: refundAmount}("");
        if (!ethTransferSuccess){
            revert FundingVault__EthTransferFailed();
        }
        
        emit Refund(msg.sender, refundAmount);       
    }

    /**
     * @dev Allows Project owners to withdraw Eth if and only if the minimum number of tokens has been sold.
     
     */

    function withdrawFunds() external {
        uint256 fundsCollected = address(this).balance;
        
        if(fundsCollected < minFundingAmount){
            revert FundingVault__minFundingAmountNotReached();
        }
        
        if(fundsWithdrawn == true){
            revert FundingVault__fundsWithdrawn();
        }
        
        uint256 developerFee = (fundsCollected * developerFeePercentage) / 100;
        uint256 amountToWithdraw = fundsCollected - developerFee;

        (bool successA, ) = payable(developerFeeAddress).call{value: developerFee}("");
        if (!successA){
            revert FundingVault__EthTransferToDeveloperFailed();
        }
        (bool successB, ) = payable(withdrawlAddress).call{value: amountToWithdraw}("");
        if (!successB){
            revert FundingVault__EthTransferToWithdrawlFailed();
        }
        fundsWithdrawn = true;
        emit FundsWithdrawn(msg.sender, amountToWithdraw);
    }

    /**
     * @dev Allows Project owners to withdraw unsold tokens from the contract at any time.
     * @param UnsoldTokenAmount amount to withdraw
    */

     function withdrawUnsoldTokens(uint256 UnsoldTokenAmount) external  {
        uint tokensHeld = participationToken.balanceOf(address(this));
        if (tokensHeld < UnsoldTokenAmount){
            revert FundingVault__NotEnoughTokens();
        }
        bool tokenTransferSuccess = participationToken.transferFrom(address(this), withdrawlAddress, UnsoldTokenAmount);
        if (!tokenTransferSuccess){
            revert FundingVault__TokenTransferFailed();
        }
       
     }

     /**
     * @dev Allows Project owners to  add more tokens to the contract at any time.
     * @param additionalTokens amount to add
    */
    function addTokens(uint256 additionalTokens) external {
        bool tokenTransferSuccess = participationToken.transferFrom(msg.sender, address(this), additionalTokens);
        if (!tokenTransferSuccess){
            revert FundingVault__TokenTransferFailed();
        }
        
    }

}