// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import {Test} from "../../../../lib/forge-std/src/Test.sol";
import {Vm} from "../../../../lib/forge-std/src/Vm.sol";
import "../../../../lib/forge-std/src/console.sol";
import "../../../../lib/forge-std/src/Script.sol";
import "../../../../lib/openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import {SocketGatewayBaseTest, SocketGateway} from "../../SocketGatewayBaseTest.sol";
import {CelerStorageWrapper} from "../../../../src/bridges/cbridge/CelerStorageWrapper.sol";
import {TransferIdDoesnotExist, OnlySocketGateway} from "../../../../src/errors/SocketErrors.sol";

contract CelerStorageWrapperTest is Test, SocketGatewayBaseTest {
    address constant randomSender = 0xD07E50196a05e6f9E6656EFaE10fc9963BEd6E57;

    SocketGateway internal socketGateway;
    CelerStorageWrapper internal celerStorageWrapper;
    address internal socketGatewayAddress;

    function setUp() public {
        socketGateway = createSocketGateway();
        socketGatewayAddress = address(socketGateway);
        celerStorageWrapper = new CelerStorageWrapper(socketGatewayAddress);
    }

    function testSetAddressInTransferId() public {
        vm.startPrank(socketGatewayAddress);

        bytes32 transferId = keccak256(abi.encodePacked(socketGatewayAddress));
        address receiverAddress = 0x4866EB53F8Ab65473F13AA94B95Ca4722Cf751A7;

        celerStorageWrapper.setAddressForTransferId(
            transferId,
            receiverAddress
        );

        address receiverAddressFromMap = celerStorageWrapper
            .getAddressFromTransferId(transferId);
        assertEq(receiverAddressFromMap, receiverAddress);

        vm.stopPrank();
    }

    function testDeleteTransferId() public {
        vm.startPrank(socketGatewayAddress);

        bytes32 transferId = keccak256(abi.encodePacked(socketGatewayAddress));
        address receiverAddress = 0x4866EB53F8Ab65473F13AA94B95Ca4722Cf751A7;

        celerStorageWrapper.setAddressForTransferId(
            transferId,
            receiverAddress
        );

        address receiverAddressFromMap = celerStorageWrapper
            .getAddressFromTransferId(transferId);
        assertEq(receiverAddressFromMap, receiverAddress);

        celerStorageWrapper.deleteTransferId(transferId);
        receiverAddressFromMap = celerStorageWrapper.getAddressFromTransferId(
            transferId
        );
        assertEq(receiverAddressFromMap, address(0));

        vm.stopPrank();
    }

    function testDeleteNonExistingTransferId() public {
        vm.startPrank(socketGatewayAddress);

        vm.expectRevert(TransferIdDoesnotExist.selector);
        bytes32 transferId = keccak256(abi.encodePacked(socketGatewayAddress));
        celerStorageWrapper.deleteTransferId(transferId);

        vm.stopPrank();
    }

    function testNonSocketGatewayCantSetTransferId() public {
        vm.startPrank(randomSender);

        bytes32 transferId = keccak256(abi.encodePacked(socketGatewayAddress));
        address receiverAddress = 0x4866EB53F8Ab65473F13AA94B95Ca4722Cf751A7;

        vm.expectRevert(OnlySocketGateway.selector);
        celerStorageWrapper.setAddressForTransferId(
            transferId,
            receiverAddress
        );

        vm.stopPrank();
    }

    function testNonSocketGatewayCantDeleteTransferId() public {
        vm.startPrank(socketGatewayAddress);

        bytes32 transferId = keccak256(abi.encodePacked(socketGatewayAddress));
        address receiverAddress = 0x4866EB53F8Ab65473F13AA94B95Ca4722Cf751A7;

        celerStorageWrapper.setAddressForTransferId(
            transferId,
            receiverAddress
        );

        address receiverAddressFromMap = celerStorageWrapper
            .getAddressFromTransferId(transferId);
        assertEq(receiverAddressFromMap, receiverAddress);

        vm.stopPrank();

        vm.startPrank(randomSender);

        vm.expectRevert(OnlySocketGateway.selector);
        celerStorageWrapper.deleteTransferId(transferId);

        vm.stopPrank();
    }
}
