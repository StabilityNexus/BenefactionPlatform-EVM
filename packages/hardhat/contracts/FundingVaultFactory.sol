// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

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
 * external functions
 * public functions
 * internal functions
 * private functions
 * view functions
 * pure functions
 * getters
 */

import {FundingVault} from "./FundingVault.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title FundingVaultFactory
 * @author Muhammad Zain Nasir
 * @notice This is the FundingVaultFactory contract that will be used for deployment and keeping track of all the funding vaults.
 */
contract FundingVaultFactory{
    // Errors //
    error FundingVaultFactory__CannotBeAZeroAddress();
    error FundingVaultFactory__deadlineCannotBeInThePast();
    error FundingVaultFactory__MinFundingAmountCanNotBeZero();
    error FundingVault__TokenTransferFailed();



    // State Variables //
    IERC20 private participationToken;
    uint256 private s_fundingVaultIdCounter;

    mapping(uint256 fundingVaultId => address fundingVault) private s_fundingVaults;


    // Events //
    event FundingVaultDeployed(address indexed fundingVault);
    event TransferTokens(address indexed token, address indexed recepient, uint256 amount);

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
    function deployFundingVault(
        address _participationToken,
        uint256 _participationTokenAmount,  
        uint256 _minFundingAmount,
        uint256 _blockLimit,
        uint256 _exchangeRate,
        address _withdrawlAddress,
        address _developerFeeAddress, 
        uint256 _developerFeePercentage, 
        string memory _projectURL
    ) external returns (address) {
        if (_participationToken == address(0) || _withdrawlAddress == address(0) || _developerFeeAddress == address(0)){
            revert FundingVaultFactory__CannotBeAZeroAddress();
        }
        if (block.number > _blockLimit) {
            revert FundingVaultFactory__deadlineCannotBeInThePast();
        }
        if (_minFundingAmount == 0) {
            revert FundingVaultFactory__MinFundingAmountCanNotBeZero();
        }



        s_fundingVaultIdCounter++;
        uint256 fundingVaultId = s_fundingVaultIdCounter;
        participationToken = IERC20(_participationToken);

        FundingVault fundingVault = new FundingVault(
        _participationToken,
        _participationTokenAmount,  
        _minFundingAmount,
        _blockLimit,
        _exchangeRate,
        _withdrawlAddress,
        _developerFeeAddress, 
        _developerFeePercentage, 
        _projectURL
        );

        bool tokenTransferSuccess = participationToken.transferFrom(msg.sender, address(fundingVault), _participationTokenAmount);
        if (!tokenTransferSuccess){
            revert FundingVault__TokenTransferFailed();
        }

        s_fundingVaults[fundingVaultId] = address(fundingVault);
        emit FundingVaultDeployed(address(fundingVault));     
        return address(fundingVault);
    }


    // Getters //
    function getFundingVault(uint256 _fundingVaultId) external view returns (address) {
        return s_fundingVaults[_fundingVaultId];
    }

    function getTotalNumberOfFundingVaults() external view returns (uint256) {
        return s_fundingVaultIdCounter;
    }
}