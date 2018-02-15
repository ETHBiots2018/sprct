pragma solidity ^0.4.19;

import "./SafeMath.sol";
import "./ERC20Interface.sol";
import "./Owned.sol";

/**
 * Contract function to receive approval and execute function in one call
 */
contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}

/**
 * SPCRToken System implementation
 */
contract SPCRToken is ERC20Interface, Owned {
    using SafeMath for uint256;

    string public constant name = "SPCRToken";
    string public constant symbol = "SPC";
    uint8 public constant decimals = 18; // TODO

    uint256 public _totalSupply;

    mapping (address => mapping (address => uint256)) allowedSpcrtBasic;

    mapping (address => uint256) spcrtBasic;
    mapping (address => uint256) spcrtReputation;

    struct BPFRRequest {
        uint256 amount;
        address requester;
        address repairGuy;
    }

    // map a customer to a mapping of his/her repair orders by their id
    mapping (address => mapping (uint256 => BPFRRequest)) BPFRRequests;

    // transaction counter for every customer
    mapping (address => uint256) txCounter;

    // confirm a bpfr (as a repairGuy)
    function confirmBPFR(address customer, uint256 id) public {
        BPFRRequest req = BPFRRequests[customer][id];

        // check if request is initialized
        if (req.requester != 0x0 && req.repairGuy != 0x0) {
            // increase balance of requester (mint)
            spcrtBasic[req.requester] += req.amount;
		    _totalSupply = _totalSupply.add(req.amount);

            // remove the request
            delete BPFRRequests[customer][id];
        }
    }

    // repair transaction
    function transferRepair(
        address customer,
        address repairGuy,
        uint256 tokens,
        uint256 bpfrAmount,
        bool bpfrReq
    ) public returns (bool success) {
        spcrtBasic[customer] = spcrtBasic[customer].sub(tokens);
        spcrtBasic[repairGuy] = spcrtBasic[repairGuy].add(tokens);

        // issue a bpfr requst if bpfReq is set
        if (bpfrReq) {
            uint256 newID = txCounter[customer]++;
            BPFRRequests[customer][newID] = BPFRRequest(bpfrAmount, customer, repairGuy);
        }

        // update repairGuy reputation
        spcrtReputation[repairGuy] += 1;

        Transfer(customer, repairGuy, tokens);
        return true;
    }

    // query reputation of an address
    function getReputation(address addr) public returns (uint256 rep) {
        return spcrtReputation[addr];
    }

    /*
     * ERC20 Interface implementations
     */

    function totalSupply() public constant returns (uint) {
        return _totalSupply  - spcrtBasic[address(0)];
    }

    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return spcrtBasic[tokenOwner];
    }

    function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
        return allowedSpcrtBasic[tokenOwner][spender];
    }

    function transfer(address to, uint tokens) public returns (bool success) {
        spcrtBasic[msg.sender] = spcrtBasic[msg.sender].sub(tokens);
        spcrtBasic[to] = spcrtBasic[to].add(tokens);
        Transfer(msg.sender, to, tokens);
        return true;
    }

    function approve(address spender, uint tokens) public returns (bool success) {
        allowedSpcrtBasic[msg.sender][spender] = tokens;
        Approval(msg.sender, spender, tokens);
        return true;
    }

    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        spcrtBasic[from] = spcrtBasic[from].sub(tokens);
        allowedSpcrtBasic[from][msg.sender] = allowedSpcrtBasic[from][msg.sender].sub(tokens);
        spcrtBasic[to] = spcrtBasic[to].add(tokens);
        Transfer(from, to, tokens);
        return true;
    }

    /**
     * Mint coins for recycling
     */
    function mintRecycle(address tokenOwner, uint256 tokens) public {
        spcrtBasic[tokenOwner] = spcrtBasic[tokenOwner].add(tokens);
		_totalSupply = _totalSupply.add(tokens);
    }

    /**
     * Mint coins referrals
     */
    function mintReferral(address tokenOwner, uint256 tokens) public {
		spcrtBasic[tokenOwner] = spcrtBasic[tokenOwner].add(tokens);
		_totalSupply = _totalSupply.add(tokens);
	}

    /**
     * Mint for collection mechanism
     */
    function mintCollection(address objReceiver, uint256 tokens) public {
        spcrtBasic[msg.sender] += tokens;
        spcrtBasic[objReceiver] += tokens;
        _totalSupply = _totalSupply.add(tokens * 2);
    }

    /**
     * Don't accept ethers
     */
    function () public payable {
        revert();
    }

    /**
     * Update reputation
     */
    function mintReputation(address repOwner, uint256 tokens) public onlyOwner returns (bool success) {
    }
}

