// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract RestrauntOrder {
    address public restraunt;

    // Structure of the Order
        struct OrderContractData {
        string Delivery_date; 
        address[] Accounts_payable; 
        int Iceberg_lettuce;
        int White_onion;
        int Red_onion;
        int Whole_egg;
        int Tomato;
        string Order_list;
        bool isCompleted; 
    }


    // Mapping to store quality contract information based on contract ID
    mapping (uint256 => OrderContractData) public OrderContracts;

    // Counter to keep track of the total number of quality contracts
    uint256 public contractCount;

    // Event triggered when a new quality contract is created
    event OrderContractCreated(
        uint256 contractId, 
        string Delivery_date, 
        address[] Accounts_payable, 
        int Iceberg_lettuce, 
        int White_onion, 
        int Red_Onion, 
        int Whole_egg, 
        int Tomato, 
        string Order_list
        );

    // Contract constructor, executed once during deployment
    constructor() {restraunt = msg.sender;}
        
    // Modifier sets access to only the restraunt who creates the contract
        modifier onlyRestraunt() {
        require(msg.sender == restraunt, "Only the restruant can execute this");
        _;
    }

    // Contract creation function
    function createOrderContract(
    string memory Delivery_date, 
    address[] memory Accounts_payable, 
    int Iceberg_lettuce, 
    int White_onion, 
    int Red_onion, 
    int Whole_egg, 
    int Tomato, 
    string memory Order_list) 
        public onlyRestraunt {
        contractCount++;
        OrderContracts[contractCount] = OrderContractData(Delivery_date, Accounts_payable, 
        Iceberg_lettuce, White_onion, Red_onion, Whole_egg, Tomato, Order_list, false);

        emit OrderContractCreated(contractCount, Delivery_date, Accounts_payable, 
        Iceberg_lettuce, White_onion, Red_onion, Whole_egg, Tomato, Order_list);
    }


    // Function to mark a order contract as completed
    function completeOrderContract(uint256 _contractId) public onlyRestraunt {
        // Check if the provided contract ID is valid
        require(_contractId > 0 && _contractId <= contractCount, "Invalid contract ID");
            // Mark the order contract as completed
            OrderContracts[_contractId].isCompleted = true;
    }


    // Return contract details from ID
    function getOrderContractDetails(uint256 _contractId) public view returns 
    (string memory, address[] memory, int, int, int, int, int, string memory, bool) 
    {
        // Check for valid ID 
        require(_contractId > 0 && _contractId <= contractCount, "Invalid contract ID");
        // Return contract details
        OrderContractData storage contractData = OrderContracts[_contractId];
            return (contractData.Delivery_date, 
            contractData.Accounts_payable, 
            contractData.Iceberg_lettuce, 
            contractData.White_onion, 
            contractData.Red_onion, 
            contractData.Whole_egg, 
            contractData.Tomato, 
            contractData.Order_list,
            contractData.isCompleted
            );
    }


    // Function for stakeholders to perform quality check
    function performQualityCheck(uint256 _contractId) public {
    // Check if the provided contract ID is valid
    require(_contractId > 0 && _contractId <= contractCount, "Invalid contract ID");
        // Check if the caller is one of the stakeholders
        bool isStakeholder = false;
            for (uint i = 0; i < OrderContracts[_contractId].Accounts_payable.length; i++) {
            if (OrderContracts[_contractId].Accounts_payable[i] == msg.sender) {
            isStakeholder = true;
            break;
            }
        }
        require(isStakeholder, "Only stakeholders can perform quality check");
            // Perform quality check logic (replace with actual quality check logic)
            OrderContracts[_contractId].isCompleted = true;
    }
    }
