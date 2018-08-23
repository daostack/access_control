pragma solidity ^0.4.24;

import "../Protected.sol";

contract Company is Protected {

    struct Employee {
        uint salary;
        uint lastPayDate;
    }

    mapping(address => Employee) employees;
    address COO;

    constructor(address _HRCompany, address _COO) {
        // The sender has unlimited access to `manageHRCompany`
        grantFullKey("manageHRCompany", msg.sender);
        COO = _COO;
    }

    function hireHRCompany(address _HRCompany, uint80 n_employees)
        public
        guarantee(unlock("manageHRCompany")) // the sender can manage HR comapines
    {
        // Allow the HRCompany to register up to `n_employees`
        grantKey(
            "registerEmployee",
            _HRCompany,
            false,      // not assignable to other accounts
            0,          // effective immediately
            0,          // no expiration
            n_employees // can be used up to `n_employees` times
        );
    }

    function fireHRCompany(address _HRCompany)
        public
        guarantee(unlock("manageHRCompany")) // the sender can manage HR comapines
    {
        // Revoke access to `registerEmployee`
        revokeOwnerKey("registerEmployee", _HRCompany);
    }

    function registerEmployee(address _employee, uint _salary)
        public
        guarantee(unlock("registerEmployee"))
    {
        require(employees[_employee].salary == 0, "Employee already registered");
        require(_salary > 0, "Salary must be greater than zero");
        employees[_employee].salary = _salary;
        employees[_employee].lastPayDate = now;

        // Next payday for this employee is at least a month from now
        grantKey(
            lockId("payout", _employee),
            COO,
            true,          // assignable to other accounts
            now + 30 days, // can be called in at least a month from now
            0,             // no expiration
            1              // one time use
        );
    }

    function payout(address _employee)
        public
        // The sender can payout to this employee
        guarantee(unlock(lockId("payout", _employee)))
    {
        uint salary = employees[_employee].salary;
        require(salary > 0, "Employee is not registered");
        _employee.transfer(salary * (now - employees[_employee].lastPayDate) / 30 days);
        employees[_employee].lastPayDate = now;

        // Next payday is at least a month from now
        grantKey(
            lockId("payout", _employee),
            COO,
            true,          // assignable to other accounts
            now + 30 days, // can be called in at least a month from now
            0,             // no expiration
            1              // one time use
        );
    }
}