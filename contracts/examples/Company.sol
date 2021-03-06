pragma solidity ^0.4.24;

import "../Permissioned.sol";


contract Company is Permissioned {

    struct Employee {
        uint salary;
        uint lastPayDate;
    }

    mapping(address => Employee) employees;
    address coo;

    constructor(address _coo) public {
        // The sender has unlimited access to `manageHRCompany`
        grantFullKey("manageHRCompany", msg.sender);
        coo = _coo;
    }

    function hireHRCompany(address _hrCompany, uint80 nEmployees)
        public
        guarentee(unlock("manageHRCompany")) // the sender can manage HR comapines
    {
        // Allow the HRCompany to register up to `nEmployees`
        grantKey(
            "registerEmployee",
            _hrCompany,
            false,      // not assignable to other accounts
            0,          // effective immediately
            0,          // no expiration
            nEmployees // can be used up to `nEmployees` times
        );
    }

    function fireHRCompany(address _hrCompany)
        public
        guarentee(unlock("manageHRCompany")) // the sender can manage HR comapines
    {
        // Revoke access to `registerEmployee`
        revokeOwnerKey("registerEmployee", _hrCompany);
    }

    function registerEmployee(address _employee, uint _salary)
        public
        guarentee(unlock("registerEmployee"))
    {
        require(employees[_employee].salary == 0, "Employee already registered");
        require(_salary > 0, "Salary must be greater than zero");
        employees[_employee].salary = _salary;
        employees[_employee].lastPayDate = now;

        // Next payday for this employee is at least a month from now
        grantKey(
            keccak256("payout",_employee),
            coo,
            true,          // assignable to other accounts
            now + 30 days, // can be called in at least a month from now
            0,             // no expiration
            1              // one time use
        );
    }

    function payout(address _employee)
        public
        // The sender can payout to this employee
        guarentee(unlock(keccak256("payout",_employee)))
    {
        uint salary = employees[_employee].salary;
        require(salary > 0, "Employee is not registered");
        _employee.transfer(salary * (now - employees[_employee].lastPayDate) / 30 days);
        employees[_employee].lastPayDate = now;

        // Next payday is at least a month from now
        grantKey(
            keccak256("payout",_employee),
            coo,
            true,          // assignable to other accounts
            now + 30 days, // can be called in at least a month from now
            0,             // no expiration
            1              // one time use
        );
    }
}
