// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0 <0.9.0;

contract TaskManagement {

    enum TaskStatus {Pending, Running, Completed}

    struct Task {
        address assignee;
        TaskStatus status;
        string taskDesc;
    }

    Task[] private _taskList; 
    address owner;

    constructor() {
        owner = msg.sender;
    }

    modifier checkIndexRange(uint taskIndex) {
        require(taskIndex < _taskList.length, "Task Index out of range");
        _;
    }
 
    modifier onlyOwner(){
        require(msg.sender == owner, "Access Denied!!");
        _;
    }

    function createTask(address _assignee, string memory _taskDesc) public payable {
        require(msg.value > 0.0001 ether, "Not enough ethers!");
        _taskList.push(Task({assignee: _assignee, taskDesc: _taskDesc, status: TaskStatus.Pending}));
    }

    function startTask(uint _taskIndex) public checkIndexRange(_taskIndex) {
        _taskList[_taskIndex].status = TaskStatus.Running;
    }

    function completeTask(uint _taskIndex) public checkIndexRange(_taskIndex) {
        _taskList[_taskIndex].status = TaskStatus.Completed;
    }

    function getTaskStatus(uint _taskIndex) public view checkIndexRange(_taskIndex) returns (TaskStatus) {
        return _taskList[_taskIndex].status;
    }

    function getTaskAssignee(uint _taskIndex) public view checkIndexRange(_taskIndex) returns (address) {
        return _taskList[_taskIndex].assignee;
    }

    function withdrawFunds(address _myaddr) public onlyOwner() {
        payable(_myaddr).transfer(address(this).balance);
    }

}
