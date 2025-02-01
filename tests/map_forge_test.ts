import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types,
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Can create new itinerary",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const title = "Paris Adventure";
    const description = "A weekend in Paris";
    const price = 100;
    const locations = ["Eiffel Tower", "Louvre", "Notre Dame"];
    const details = "Detailed guide for Paris";

    let block = chain.mineBlock([
      Tx.contractCall('map_forge', 'create-itinerary', [
        types.ascii(title),
        types.utf8(description),
        types.uint(price),
        types.list(locations.map(l => types.utf8(l))),
        types.utf8(details)
      ], deployer.address)
    ]);

    block.receipts[0].result.expectOk().expectUint(0);
  },
});

Clarinet.test({
  name: "Cannot create itinerary with empty locations",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    
    let block = chain.mineBlock([
      Tx.contractCall('map_forge', 'create-itinerary', [
        types.ascii("Test"),
        types.utf8("Test desc"),
        types.uint(100),
        types.list([]),
        types.utf8("Details")
      ], deployer.address)
    ]);

    block.receipts[0].result.expectErr().expectUint(104);
  },
});

Clarinet.test({
  name: "Cannot rate with invalid rating value",
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

    // Try invalid rating
    let ratingBlock = chain.mineBlock([
      Tx.contractCall('map_forge', 'rate-itinerary', [
        types.uint(0),
        types.uint(6),
        types.utf8("Great itinerary!")
      ], buyer.address)
    ]);

    ratingBlock.receipts[0].result.expectErr().expectUint(105);
  },
});
