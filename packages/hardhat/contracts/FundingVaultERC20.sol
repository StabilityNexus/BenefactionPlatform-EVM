// SPDX-License-Identifier: AEL

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
pragma solidity ^0.8.18;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title FundingVault
 * @author Muhammad Zain Nasir
 * @notice A contract that allows users to deposit ERC20 tokens and receive proof-of-funding tokens in return. Project owners can withdraw funds once the minimum funding amount is reached.
 */
contract FundingVault {

    // Errors //
    error MinFundingAmountReached();
    error MinFundingAmountNotReached();
    error DeadlineNotPassed(); 
    error NotEnoughTokens(); 
    error OwnerOnly();


    // State Variables //
    using SafeERC20 for IERC20;
    IERC20 public immutable fundingToken; 
    IERC20 public immutable proofOfFundingToken; // The token that will be used as proof-of-funding token to incentivise contributions
    uint256 public proofOfFundingTokenAmount; // The initial  proof-of-funding token amount which will be in fundingVault
    uint256 public timestamp; // The date limit until which withdrawal or after which refund is allowed.
    uint256 public immutable minFundingAmount; // The minimum amount of ETH required in the contract to enable withdrawal.
    uint256 public exchangeRate; // The exchange rate of ETH per token
    address public withdrawalAddress; // WithdrawalAddress is also considered as owner of the Vault. 
    address private developerFeeAddress; // Developer address
    uint256 private developerFeePercentage; // Developer percentage in funds collected
    string  public projectURL; // A link or hash containing the project's information (e.g., GitHub repository).
    string public projectTitle; // Name of the Project
    string public projectDescription; // Short description of the project
    uint256 private amountRaised; // Variable to know if minimum funding raised or not


    /** 
    * @dev A vault is represented as a struct  
    */ 

    struct Vault {
        address withdrawalAddress;
        address proofOfFundingToken;
        uint256 proofOfFundingTokenAmount;  
        uint256 minFundingAmount;
        uint256 timestamp;
        uint256 exchangeRate;
        string projectURL;
        string projectTitle;
        string projectDescription;
        address fundingToken;
        address developerFeeAddress;
        uint256 developerFeePercentage;
    }
    

    // Events //
    event TokensPurchased(address indexed from, uint256 indexed amount);
    event Refund(address indexed user, uint256 indexed amount);
    event FundsWithdrawn(address indexed user, uint256 amount);


    // Modifiers //

    modifier onlyOwner {
        if (msg.sender != withdrawalAddress)  revert OwnerOnly();
        _;
    }


    // Functions //
    
     constructor(Vault memory params){
         proofOfFundingToken = IERC20(params.proofOfFundingToken);
        fundingToken = IERC20(params.fundingToken);
        proofOfFundingTokenAmount = params.proofOfFundingTokenAmount;
        minFundingAmount = params.minFundingAmount;
        timestamp = params.timestamp;
        exchangeRate = params.exchangeRate;
        withdrawalAddress = params.withdrawalAddress;
        developerFeeAddress = params.developerFeeAddress;
        developerFeePercentage = params.developerFeePercentage;
        projectURL = params.projectURL;
        projectTitle = params.projectTitle;
        projectDescription = params.projectDescription;
    }

    
    /**
     * @dev Allows users to deposit Ether and purchase proof-of-funding token based on exchange rate
     */
    function purchaseTokens(uint256 amount) external  {

       if (amount == 0) revert MinFundingAmountNotReached();

        uint256 tokenAmount = amount * exchangeRate;
        if (proofOfFundingToken.balanceOf(address(this)) < tokenAmount) revert NotEnoughTokens();

        fundingToken.safeTransferFrom(msg.sender, address(this), amount);
        proofOfFundingToken.safeTransfer(msg.sender, tokenAmount);

        amountRaised += amount;

        emit TokensPurchased(msg.sender, tokenAmount);
    }

    /**
     * @dev Allows users to exchange tokens for Eth (at exchange rate) if and only if the deadline has passed and the minimum number of tokens has not been sold.
     */

    function refundTokens() external payable{

        if (block.timestamp < timestamp)  revert DeadlineNotPassed();
        
        if (amountRaised >= minFundingAmount) revert MinFundingAmountReached();
        
        uint256 tokensHeld = proofOfFundingToken.balanceOf(msg.sender);
        uint256 refundAmount = tokensHeld / exchangeRate;

        proofOfFundingToken.safeTransferFrom(msg.sender, address(this), tokensHeld);
        fundingToken.safeTransfer(msg.sender, refundAmount);

        emit Refund(msg.sender, refundAmount);       
    }

    /**
     * @dev Allows Project owners to withdraw Eth if and only if the minimum number of tokens has been sold.
     
     */

    function withdrawFunds() external onlyOwner {
    
        if (amountRaised < minFundingAmount) revert MinFundingAmountNotReached();

        uint256 developerFee = (amountRaised * developerFeePercentage) / 100;
        uint256 amountToWithdraw = amountRaised - developerFee;

        fundingToken.safeTransfer(developerFeeAddress, developerFee);
        fundingToken.safeTransfer(withdrawalAddress, amountToWithdraw);
        emit FundsWithdrawn(msg.sender, amountToWithdraw);




    }

    /**
     * @dev Allows Project owners to withdraw unsold tokens from the contract at any time.
     * @param UnsoldTokenAmount amount to withdraw
    */

     function withdrawUnsoldTokens(uint256 UnsoldTokenAmount) external onlyOwner {
        if (proofOfFundingToken.balanceOf(address(this)) < UnsoldTokenAmount) revert NotEnoughTokens();
        
        proofOfFundingToken.safeTransferFrom(address(this),withdrawalAddress,UnsoldTokenAmount);
       
     }

     /**
     * @dev Allows Project owners to  add more tokens to the contract at any time.
     * @param additionalTokens amount to add
    */
    function addTokens(uint256 additionalTokens) external onlyOwner {
        proofOfFundingToken.safeTransferFrom(msg.sender,address(this),additionalTokens);
    }

    /**
     * @notice Get funding vault details
     * @dev to access all necessary parameters of the funding vault
     */ 
    function getVault() external view returns (Vault memory) {
        return Vault({
            withdrawalAddress: withdrawalAddress,
            proofOfFundingToken: address(proofOfFundingToken),
            proofOfFundingTokenAmount: proofOfFundingTokenAmount,
            minFundingAmount: minFundingAmount,
            timestamp: timestamp,
            exchangeRate: exchangeRate,
            projectURL: projectURL,
            projectTitle: projectTitle,
            projectDescription: projectDescription,
            fundingToken: address(fundingToken),
            developerFeeAddress: developerFeeAddress,
            developerFeePercentage: developerFeePercentage
        });
    }

}