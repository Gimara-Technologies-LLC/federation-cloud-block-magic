import {  ContractTransactionResponse , ethers } from "ethers";


export const getCcipMessageId = async (tx: ContractTransactionResponse, provider: ethers.JsonRpcProvider) => {
    // Simulate a call to the router to fetch the messageID
    const call = {
        from: tx.from,
        to: tx.to,
        data: tx.data,
        gasLimit: tx.gasLimit,
        gasPrice: tx.gasPrice,
        value: tx.value,
    };

    // Simulate a contract call with the transaction data at the block before the transaction
    const messageId = await provider.call(call);

    console.log(`✅ You can now monitor the token transfer status via CCIP Explorer by searching for CCIP Message ID: ${messageId}`);
}
