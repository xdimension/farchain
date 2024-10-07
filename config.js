require('dotenv').config();

exports.config = {

    ticketPrice: 0.0001,            // The price of 1 ticket to join

    VRFSubscriptionId: process.env['VRF_SUBSCRIPTION_ID'],  // VRF Subscription Id
    VRFCoordinator: process.env['VRF_COORDINATOR'],         // VRF Coordinator address
    VRFKeyHash: process.env['VRF_KEY_HASH'],                // VRF Key Hash
}