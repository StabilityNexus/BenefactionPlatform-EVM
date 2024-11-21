// SPDX-License-Identifier: MIT

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
pragma solidity ^0.8.26;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title FundingVault
 * @author Muhammad Zain Nasir
 * @notice A contract that allows users to deposit funds and receive participation tokens in return box creator can call WithdrawFunds if there enough funds collected
 */
contract FundingVault{

 // Errors //
    error minFundingAmountReached();
    error minFundingAmountNotReached();
    error err_deadlineNotPassed(); 
    error NotEnoughTokens(); 
    error err_fundsWithdrawn();
    error EthTransferFailed();
    error EthTransferToDeveloperFailed();
    error EthTransferToWithdrawlFailed();


    // State Variables //
    using SafeERC20 for IERC20;
    IERC20 private immutable participationToken;
    uint256 private participationTokenAmount;
    uint256 private timeStamp;
    uint256 private immutable minFundingAmount; //The minimum amount of ETH required in the contract to enable withdrawal.
    uint256 private exchangeRate; //The exchange rate of ERG per token
    address private projectOwner;
    address private withdrawlAddress;
    address private developerFeeAddress; //develper address
    uint256 private developerFeePercentage; 
    string  private projectURL;
    string private projectTitle;
    string private projectDescription;
    bool private fundsWithdrawn;


    /** 
    * @dev A vault is represented as a struct  
    */ 

    struct Vault {
        address withdrawlAddress;
        address participationToken;
        uint256 participationTokenAmount;  
        uint256 minFundingAmount;
        uint256 timeStamp;
        uint256 exchangeRate;
        string projectURL;
        string projectTitle;
        string projectDescription;
    }
    


    // Events //
    event TokensPurchased(address indexed from, uint256 indexed amount);
    event Refund(address indexed user, uint256 indexed amount);
    event FundsWithdrawn(address indexed user, uint256 amount);


    // Functions //

     /**
     * @param _participationToken The token that will be used as participation token to incentivise donators
     * @param _participationTokenAmount Theinitial  participation token amount which will be in fundingVault
     * @param _minFundingAmount The minimum amount required to make withdraw of funds possible
     * @param _timeStamp The date (block height) limit until which withdrawal or after which refund is allowed.
     * @param _withdrawlAddress The address for withdrawl of funds
     * @param _developerFeeAddress the address for the developer fee
     * @param _developerFeePercentage the percentage fee for the developer.
     * @param _projectURL A link or hash containing the project's information (e.g., GitHub repository).
     */
    
     constructor (
        address _participationToken,
        uint256 _participationTokenAmount,  
        uint256 _minFundingAmount,
        uint256 _timeStamp,
        uint256 _exchangeRate,
        address _withdrawlAddress,
        address _developerFeeAddress, 
        uint256 _developerFeePercentage, 
        string memory _projectURL,
        string memory _projectTitle,
        string memory _projectDescription
    ) {
        
        participationToken  = IERC20(_participationToken);
        participationTokenAmount  = _participationTokenAmount ;
        minFundingAmount = _minFundingAmount;
        timeStamp = _timeStamp;
        exchangeRate = _exchangeRate;
        withdrawlAddress = _withdrawlAddress;
        developerFeeAddress =  _developerFeeAddress;
        developerFeePercentage = _developerFeePercentage;
        projectURL = _projectURL;
        projectTitle = _projectTitle;
        projectDescription = _projectDescription;
    }

    
    /**
     * @dev Allows users to deposit Ether and purchase participation tokens based on exchange rate
     */
    function purchaseTokens() external payable {
         
        uint256 tokenAmount = msg.value * exchangeRate;

        if (participationToken.balanceOf(address(this)) < tokenAmount)
        {
            revert NotEnoughTokens();
        }

        participationToken.safeTransfer(msg.sender,tokenAmount);
        
        emit TokensPurchased(msg.sender, tokenAmount);
    }

    /**
     * @dev Allows users to exchange tokens for Eth (at exchange rate) if and only if the deadline has passed and the minimum number of tokens has not been sold.
     */

    function refundTokens() external payable{

        if (block.timestamp < timeStamp) {
            revert err_deadlineNotPassed();
        }

        if(address(this).balance >= minFundingAmount){
        revert minFundingAmountReached();
        }
        uint tokensHeld = participationToken.balanceOf(msg.sender);
        uint256 refundAmount = tokensHeld * exchangeRate;

        participationToken.safeTransferFrom(msg.sender,address(this),tokensHeld);
       
        (bool ethTransferSuccess, ) = payable(msg.sender).call{value: refundAmount}("");
        if (!ethTransferSuccess){
            revert EthTransferFailed();
        }
        
        emit Refund(msg.sender, refundAmount);       
    }

    /**
     * @dev Allows Project owners to withdraw Eth if and only if the minimum number of tokens has been sold.
     
     */

    function withdrawFunds() external {
        uint256 fundsCollected = address(this).balance;
        
        if(fundsCollected < minFundingAmount){
            revert minFundingAmountNotReached();
        }
        
        if(fundsWithdrawn == true){
            revert err_fundsWithdrawn();
        }
        
        uint256 developerFee = (fundsCollected * developerFeePercentage) / 100;
        uint256 amountToWithdraw = fundsCollected - developerFee;

        (bool successA, ) = payable(developerFeeAddress).call{value: developerFee}("");
        if (!successA){
            revert EthTransferToDeveloperFailed();
        }
        (bool successB, ) = payable(withdrawlAddress).call{value: amountToWithdraw}("");
        if (!successB){
            revert EthTransferToWithdrawlFailed();
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
            revert NotEnoughTokens();
        }
        
        participationToken.safeTransferFrom(address(this),withdrawlAddress,UnsoldTokenAmount);
       
     }

     /**
     * @dev Allows Project owners to  add more tokens to the contract at any time.
     * @param additionalTokens amount to add
    */
    function addTokens(uint256 additionalTokens) external {
        participationToken.safeTransferFrom(msg.sender,address(this),additionalTokens);
    }

    /**
     * @notice Get funding vault details
     * @dev to access all necessary parameters of the funding vault
     */ 
    function getVaults() external view returns(Vault memory)
    {
        Vault memory VaultDetails;
        VaultDetails.withdrawlAddress = withdrawlAddress;
        VaultDetails.participationToken  = address(participationToken);
        VaultDetails.participationTokenAmount  = participationTokenAmount ;
        VaultDetails.minFundingAmount = minFundingAmount;
        VaultDetails.timeStamp = timeStamp;
        VaultDetails.exchangeRate = exchangeRate;
        VaultDetails.projectURL = projectURL;
        VaultDetails.projectTitle = projectTitle;
        VaultDetails.projectDescription = projectDescription;
        return VaultDetails;
    }

}