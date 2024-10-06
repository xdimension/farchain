require('dotenv').config();

exports.config = {

    ticketPrice: 0.0001,            // The price of 1 ticket to join

    LINKTokenAddress: process.env['LINK_TOKEN_ADDR'],       // LINK token address
    VRFWrapperAddress: process.env['VRF_WRAPPER_ADDR'],     // VRF wrapper address

    callbackGasLimit: 1000000,   // Gas price limit for randomness callback (only change it if you know what you do!)
}