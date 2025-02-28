import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types,
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

// [Previous tests remain unchanged]

Clarinet.test({
  name: "Cannot create itinerary with empty title or description",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    
    let block = chain.mineBlock([
      Tx.contractCall('map_forge', 'create-itinerary', [
        types.ascii(""),
        types.utf8("Test desc"),
        types.uint(100),
        types.list([types.utf8("Location 1")]),
        types.utf8("Details")
      ], deployer.address)
    ]);

    block.receipts[0].result.expectErr().expectUint(106);
  },
});

Clarinet.test({
  name: "Can withdraw earnings correctly",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const buyer = accounts.get('wallet_1')!;
    
    // Create and purchase itinerary
    let setupBlock = chain.mineBlock([
      Tx.contractCall('map_forge', 'create-itinerary', [
        types.ascii("Test Itinerary"),
        types.utf8("Test Description"),
        types.uint(100),
        types.list([types.utf8("Location 1")]),
        types.utf8("Details")
      ], deployer.address),
      Tx.contractCall('map_forge', 'purchase-itinerary', [
        types.uint(0)
      ], buyer.address)
    ]);

    // Withdraw earnings
    let withdrawBlock = chain.mineBlock([
      Tx.contractCall('map_forge', 'withdraw-earnings', [], deployer.address)
    ]);

    withdrawBlock.receipts[0].result.expectOk().expectUint(100);
  },
});
