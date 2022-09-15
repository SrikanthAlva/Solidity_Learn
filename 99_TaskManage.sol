// SPDX-License-Identifier:MIT

pragma solidity ^0.8.0;

contract TaskContract {
    // Type Declarations
    enum Status {
        New,
        InProgress,
        Closed
    }
    struct Task {
        address assignee;
        string description;
        Status status;
    }

    address public owner;

    // Task 1 - Index out of Range
    // Check in taskInprogress, taskClosed, getTaskDetails
    // whether the index provided as input is within the range of values acceptable

    // Task 1.5 - Throw Error
    // If index is out of range throw Error Message "Index out of Range"

    // Task 2 - Set an owner to this contract

    // Task 3 - Use Modifier whether necessary to optimize code.

    constructor() {
        owner = msg.sender;
    }

    modifier indexRange(uint index) {
        require(index < taskManager.length, "Index out of Range");
        _;
    }

    Task[] public taskManager;

    function addNewTask(address asign, string memory desc) public {
        taskManager.push(Task(asign, desc, Status.New));
    }

    function taskInprogress(uint index) public indexRange(index) {
        taskManager[index].status = Status.InProgress;
    }

    function getTaskDetails(uint index)
        public
        view
        indexRange(index)
        returns (Task memory)
    {
        return taskManager[index];
    }

    function taskClosed(uint index) public indexRange(index) {
        taskManager[index].status = Status.Closed;
    }
}
