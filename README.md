# Region-dApp
Fully decentralized application for manage Plot Regions

# Short description about test task.
I've wrote this in Solidity 0.8.11 available from 0.7.0 to latest version.
I've tested in Remix IDE and Truffle local network.
I think the 3 proposals for Storing the maps (coordinates), Comparing if some terrain is not available, Voting system are fully implemented in my solution.
The solution consists of 2 parts - structs and library for using Reactangle, and Religion contract.

You can find explainations for each functions and structs in "LibRectangle.sol".
Let me get into main solution "Region".
# === State variables ===
- Maps data is used for storing global maps data. (Initially it only stores [0, 0] X [30, 30] by contract creator set in contructor)
- Plots data is used for storing plots ownership information for each owners. And all owners are voters.
- Getting terrain request proposals are stored in "requestQueue" as mapping type
- Extending Map proposal

# === First Requirement : getting terrain on that map ===
Once the map is initialized as [0, 0] X [30, 30] by creator, the current owner is contract creator.
Function "requestTerrain" allows caller can request getting terrain inside the map. I implemented validation to check if requesting terrain is valid using LibRectangle.
If the request is valid, it is added to proposal queue to handle in chronological order.
Only contract creator can approve this request. I used onlyBy modifier to see if the caller is creator.
Contract creator(current owner) can approve the request via function "approveRequest". The validation is essential for every approvement.
Once creator approved, the terrain is not available for after request. And it updates plots data (voters data and ownership information)

# === SECOND Requirement: extending the map ===
If only every voters votes to proposal the proposal is approved.
In constructor, initializing map adds a proposal for extending map which is voted by creator. The creator is the only owner at the moment, so the map is initialized as [0, 0] X [30, 30]. (extendingMap, addMap())

Contract creator and make proposal for extending map using "proposeExtendingMap".
Only owners can votes("voteExtendingMap"), so it needs to check if the voter is valid owner.
When all voters have participated, add the map("addMap") and end the voting(Line 72 ~ 77).
