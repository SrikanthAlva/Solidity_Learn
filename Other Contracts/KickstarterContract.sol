pragma solidity >=0.5.0 <0.6.0;

contract KickstarterContract {
    struct Request {
        string description;
        uint256 value;
        address recipient;
        bool completed;
        uint256 numberOfVoters;
        mapping(address => bool) voters;
    }

    mapping(address => uint256) public contributions;
    uint256 public totalContributors;
    uint256 public minimumContribution;
    uint256 public deadline;
    uint256 public goal;
    uint256 public raisedAmount = 0;
    address public admin;

    Request[] public requests;

    constructor(uint _minimumContribution, uint _deadline, uint _goal) {
        minimumContribution = _minimumContribution;
        deadline = block.number + _deadline;
        goal = _goal;
        admin = msg.sender;
    }

    function contribute() public payable {
        require(msg.value > minimumContribution);
        require(block.number < deadline);

        if (contributions[msg.sender] == 0) {
            totalContributors++;
        }
        contributions[msg.sender] += msg.value;
        raisedAmount += msg.value;
    }

    function getRefund() public {
        require(block.number > deadline);
        require(raisedAmount < goal);
        require(contributions[msg.sender] > 0);

        msg.sender.transfer(contributions[msg.sender]);
        contributions[msg.sender] = 0;
    }

    function createSpendingRequest(
        string memory _description,
        address _recipient,
        uint256 _value
    ) public onlyAdmin goalReached {
        Request memory newRequest =
            Request({
                description: _description,
                value: _value,
                recipient: _recipient,
                completed: false,
                numberOfVoters: 0
            });
        requests.push(newRequest);
    }

    modifier onlyAdmin() {
        require(msg.sender == admin);
        _;
    }

    modifier goalReached() {
        require(raisedAmount >= goal);
        _;
    }

    function makePayment(uint index) public onlyAdmin goalReached{
        
        Request storage thisRequest = requests[index];

        require(thisRequest.completed == false);
        require(thisRequest.numberOfVoters > totalContributors / 2);

        thisRequest.recipient.transfer(thisRequest.value);
        thisRequest.completed = true;

    }

}
