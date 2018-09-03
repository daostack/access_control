/**
 * Converts a key struct array into a JS object
 * @param {*} arr
 */
function key(arr) {
  return {
    exists: arr[0],
    assignable: arr[1],
    start: arr[2],
    expiration: arr[3],
    uses: arr[4]
  };
}

/**
 * Checks if key is all zeros
 * @param {*} key
 */
function empty(key) {
  return (
    !key.exists &&
    !key.assignable &&
    key.start.isZero() &&
    key.expiration.isZero() &&
    key.uses.isZero()
  );
}

/**
 * get event from tx logs
 * @param {*} tx
 * @param {*} name
 */
function event(tx, name) {
  const logs = tx.logs.filter(x => x.event === name);
  return logs.length ? logs[0] : null;
}

/**
 * forward a number of seconds in time
 * @param {*} blocks
 */
const forward = async seconds => {
  const jsonrpc = "2.0";
  const id = 0;
  const send = (method, params = []) =>
    web3.currentProvider.send({ id, jsonrpc, method, params });
  await send("evm_increaseTime", [seconds]);
  await send("evm_mine");
};

function now() {
  return web3.eth.getBlock(web3.eth.blockNumber).timestamp;
}

const hour = 60 * 60;

const TIME_TOLERANCE = 7; // 7 seconds tolerance

module.exports = { key, empty, event, forward, now, hour, TIME_TOLERANCE };
