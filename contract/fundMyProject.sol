// SPDX-License-Identifier: MIT  

pragma solidity >=0.7.0 <0.9.0;

interface IERC20Token {
    function transfer(address, uint256) external returns (bool);
    function approve(address, uint256) external returns (bool);
    function transferFrom(address, address, uint256) external returns (bool);
    function totalSupply() external view returns (uint256);
    function balanceOf(address) external view returns (uint256);
    function allowance(address, address) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


library SafeMath { // Only relevant functions
function sub(uint256 a, uint256 b) internal pure returns (uint256) {
  assert(b <= a);
  return a - b;
}

function add(uint256 a, uint256 b) internal pure returns (uint256)   {
  uint256 c = a + b;
  assert(c >= a);
  return c;
 }

}


contract FundMe {

    // @notice totalProjects that holds the total of Project That need support created.
    uint256 public totalProjects = 0;

    address internal cUsdTokenAddress = 0x874069Fa1Eb16D44d622F2e0Ca25eeA172369bC1;

    // @notice owner who deploy the contract, this is need for project approved by an admin
    // because only project approved by admin can recieved support in terms of funding
    address private owner;

    using SafeMath for uint256;
    
    // @notice Project struct to hold all the neccessary information needed for each project
     struct Project {
        address payable owner;
        string name;
        string image;
        string description;
        uint supporters;
        uint amountNeeded;
        uint totalAmountsRecieved;
        bool ended;
    }

    mapping (uint => Project) internal projects;

    /// @notice  contractor will executed during the deployment of the contract 
    constructor (){
       owner = msg.sender;
    }

    // @param _title the title of the project
    // @param _description the description of what the project is all about
    // @param _image the image that describes the project
    // @param _amountNeeded the amount that is required to completed the project.

    function submitProject(
        string memory _name,
        string memory _image,
        string memory _description,
        uint  _amountNeeded
    ) public {
        uint _supporters = 0;
        projects[totalProjects] = Project(
            payable(msg.sender),
            _name,
            _image,
            _description,
            _supporters,
            _amountNeeded,
            0,
            false
        );
      totalProjects++;  
    }

    // @notice readProject gets the data of a particular project stored in the project map
    // @dev It uses the project index passed as an argument to get a particular project from the project map
    // @param _index the index of a project 
    // @return Project with all the data stored in it
    function readProject (uint _index) public view returns (
        address payable,
        string memory,
        string memory,
        string memory,
        uint,
        uint,
        uint
    ){
    return (
            projects[_index].owner,
            projects[_index].name,
            projects[_index].image,
            projects[_index].description,
            projects[_index].totalAmountsRecieved,
            projects[_index].amountNeeded,
            projects[_index].supporters
        );
    }

    // @notice endProject end a project support
    // @dev It uses the project index passed as an argument to find the project and update it's end status to true
    // @param _index the index of a project 
    function endProject(uint _index) public {
        require(msg.sender == owner, "Only Admin can end a project support");
        require(projects[_index].ended == true, "Project Support Has Ended");
        projects[_index].ended = true;
    }

    // @notice supportProject allow anyone to support the project a specific amount,
    // @dev It uses the project index passed as an argument to get a particular project from the project map
    // @dev collect an amount greater than 0, add the totalAmountsRecieved and update support number
    // @param _index the index of a project 
    // @return Project with all the data stored in it
    function supportProject(uint _index) public payable {
        require(msg.value > 0, "Amount must be greater than 0!");
        require(projects[_index].ended == true, " Project Support has ended");
        require(
            msg.sender != projects[_index].owner,
            "You cannot Support your own Project"
        );
        projects[_index].totalAmountsRecieved.add(msg.value);
        projects[_index].supporters++;
    }

    // @notice getProjectsLength allow anyone get the total number of projects,
   function getProjectsLength() public view returns (uint) {
       return ( totalProjects );
   }

    // @notice withdrawFund allow project owner widthraw total amount ,
    // @dev It uses the project index passed as an argument to get a particular project from the project map
    // @dev calculate platform % percentage and send the remaining balance to the orject owner
    // @param _index the index of a project 

   function withdrawFund(uint _index) public payable {
       require(projects[_index].owner == msg.sender, "You Cannot widthraw from a project you did not create");
       require(projects[_index].ended == false, "You Cannot Withdraw until the project support has ended");
       
       // send 7% of project totalAmountsRecieved to the contract owner
       uint platformPercentage = 7;
       uint afterPercentage = projects[_index].totalAmountsRecieved * platformPercentage / 100;
       require(
           IERC20Token(cUsdTokenAddress).transferFrom(
                    owner,
                    projects[_index].owner,
                    afterPercentage
                ),
                "Transaction Failed"
       );

       require(
                IERC20Token(cUsdTokenAddress).transferFrom(
                    msg.sender,
                    projects[_index].owner,
                    projects[_index].totalAmountsRecieved.sub(afterPercentage)
                ),
            "Transaction Failed"
        );
   }
}