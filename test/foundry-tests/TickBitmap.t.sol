// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/console.sol";
import {Test} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";
import {GasSnapshot} from "../../lib/forge-gas-snapshot/src/GasSnapshot.sol";
import {TickBitmapTest} from "../../contracts/test/TickBitmapTest.sol";

contract TickBitmapTestTest is Test, GasSnapshot {
    TickBitmapTest tickBitmap;

    function setUp() public {
        tickBitmap = new TickBitmapTest();
    }

    // #isInitialized

    function test_isInitialized_isFalseAtFirst() public {
        assertEq(tickBitmap.isInitialized(1), false);
    }

    function test_isInitialized_isFlippedByFlipTick() public {
        tickBitmap.flipTick(1);

        assertEq(tickBitmap.isInitialized(1), true);
    }

    function test_isInitialized_isFlippedBackByFlipTick() public {
        tickBitmap.flipTick(1);
        tickBitmap.flipTick(1);

        assertEq(tickBitmap.isInitialized(1), false);
    }

    function test_isInitialized_isNotChangedByAnotherFlipToADifferentTick() public {
        tickBitmap.flipTick(2);

        assertEq(tickBitmap.isInitialized(1), false);
    }

    function test_isInitialized_isNotChangedByAnotherFlipToADifferentTickOnAnotherWord() public {
        tickBitmap.flipTick(1 + 256);

        assertEq(tickBitmap.isInitialized(257), true);
        assertEq(tickBitmap.isInitialized(1), false);
    }
    // #flipTick

    function test_flipTick_flipsOnlyTheSpecifiedTick() public {
        tickBitmap.flipTick(-230);

        assertEq(tickBitmap.isInitialized(-230), true);
        assertEq(tickBitmap.isInitialized(-231), false);
        assertEq(tickBitmap.isInitialized(-229), false);
        assertEq(tickBitmap.isInitialized(-230 + 256), false);
        assertEq(tickBitmap.isInitialized(-230 - 256), false);

        tickBitmap.flipTick(-230);
        assertEq(tickBitmap.isInitialized(-230), false);
        assertEq(tickBitmap.isInitialized(-231), false);
        assertEq(tickBitmap.isInitialized(-229), false);
        assertEq(tickBitmap.isInitialized(-230 + 256), false);
        assertEq(tickBitmap.isInitialized(-230 - 256), false);

        assertEq(tickBitmap.isInitialized(1), false);
    }

    function test_flipTick_revertsOnlyItself() public {
        tickBitmap.flipTick(-230);
        tickBitmap.flipTick(-259);
        tickBitmap.flipTick(-229);
        tickBitmap.flipTick(500);
        tickBitmap.flipTick(-259);
        tickBitmap.flipTick(-229);
        tickBitmap.flipTick(-259);

        assertEq(tickBitmap.isInitialized(-259), true);
        assertEq(tickBitmap.isInitialized(-229), false);
    }

    function test_flipTick_gasCostOfFlippingFirstTickInWordToInitialized() public {
        snapStart("flipTick_gasCostOfFlippingFirstTickInWordToInitialized");
        tickBitmap.getGasCostOfFlipTick(1);
        snapEnd();
    }

    function test_flipTick_gasCostOfFlippingSecondTickInWordToInitialized() public {
        tickBitmap.flipTick(0);

        snapStart("flipTick_gasCostOfFlippingSecondTickInWordToInitialized");
        tickBitmap.getGasCostOfFlipTick(1);
        snapEnd();
    }

    function test_flipTick_gasCostOfFlippingATickThatResultsInDeletingAWord() public {
        tickBitmap.flipTick(0);

        snapStart("flipTick_gasCostOfFlippingATickThatResultsInDeletingAWord");
        tickBitmap.getGasCostOfFlipTick(0);
        snapEnd();
    }

    // #nextInitializedTickWithinOneWord

    function setUpSomeTicks() internal {
        int24[9] memory ticks = [int24(-200), -55, -4, 70, 78, 84, 139, 240, 535];

        for (uint256 i; i < ticks.length - 1; i++) {
            tickBitmap.flipTick(ticks[i]);
        }
    }

    function test_nextInitializedTickWithinOneWord_lteFalse_returnsTickToRightIfAtInitializedTick() public {
        setUpSomeTicks();

        (int24 next, bool initialized) = tickBitmap.nextInitializedTickWithinOneWord(78, false);

        assertEq(next, 84);
        assertEq(initialized, true);
    }

    function test_nextInitializedTickWithinOneWord_lteFalse_returnsTickToRightIfAtInitializedTick2() public {
        setUpSomeTicks();

        (int24 next, bool initialized) = tickBitmap.nextInitializedTickWithinOneWord(-55, false);

        assertEq(next, -4);
        assertEq(initialized, true);
    }

    function test_nextInitializedTickWithinOneWord_lteFalse_returnsTheTickDirectlyToTheRight() public {
        setUpSomeTicks();

        (int24 next, bool initialized) = tickBitmap.nextInitializedTickWithinOneWord(77, false);

        assertEq(next, 78);
        assertEq(initialized, true);
    }

    function test_nextInitializedTickWithinOneWord_lteFalse_returnsTheTickDirectlyToTheRight2() public {
        setUpSomeTicks();

        (int24 next, bool initialized) = tickBitmap.nextInitializedTickWithinOneWord(-56, false);

        assertEq(next, -55);
        assertEq(initialized, true);
    }

    function test_nextInitializedTickWithinOneWord_lteFalse_returnsTheNextWordsInitializedTickIfOnTheRightBoundary()
        public
    {
        setUpSomeTicks();

        (int24 next, bool initialized) = tickBitmap.nextInitializedTickWithinOneWord(255, false);

        assertEq(next, 511);
        assertEq(initialized, false);
    }

    function test_nextInitializedTickWithinOneWord_lteFalse_returnsTheNextWordsInitializedTickIfOnTheRightBoundary2()
        public
    {
        setUpSomeTicks();

        (int24 next, bool initialized) = tickBitmap.nextInitializedTickWithinOneWord(-257, false);

        assertEq(next, -200);
        assertEq(initialized, true);
    }

    function test_nextInitializedTickWithinOneWord_lteFalse_returnsTheNextInitializedTickFromTheNextWord() public {
        setUpSomeTicks();
        tickBitmap.flipTick(340);

        (int24 next, bool initialized) = tickBitmap.nextInitializedTickWithinOneWord(328, false);

        assertEq(next, 340);
        assertEq(initialized, true);
    }

    function test_nextInitializedTickWithinOneWord_lteFalse_doesNotExceedBoundary() public {
        setUpSomeTicks();

        (int24 next, bool initialized) = tickBitmap.nextInitializedTickWithinOneWord(508, false);

        assertEq(next, 511);
        assertEq(initialized, false);
    }

    function test_nextInitializedTickWithinOneWord_lteFalse_skipsEntireWord() public {
        setUpSomeTicks();

        (int24 next, bool initialized) = tickBitmap.nextInitializedTickWithinOneWord(255, false);

        assertEq(next, 511);
        assertEq(initialized, false);
    }

    function test_nextInitializedTickWithinOneWord_lteFalse_skipsHalfWord() public {
        setUpSomeTicks();

        (int24 next, bool initialized) = tickBitmap.nextInitializedTickWithinOneWord(383, false);

        assertEq(next, 511);
        assertEq(initialized, false);
    }

    function test_nextInitializedTickWithinOneWord_lteFalse_gasCostOnBoundary() public {
        setUpSomeTicks();

        snapStart("nextInitializedTickWithinOneWord_lteFalse_gasCostOnBoundary");
        tickBitmap.getGasCostOfNextInitializedTickWithinOneWord(255, false);
        snapEnd();
    }

    function test_nextInitializedTickWithinOneWord_lteFalse_gasCostJustBelowBoundary() public {
        setUpSomeTicks();

        snapStart("nextInitializedTickWithinOneWord_lteFalse_gasCostJustBelowBoundary");
        tickBitmap.getGasCostOfNextInitializedTickWithinOneWord(254, false);
        snapEnd();
    }

    function test_nextInitializedTickWithinOneWord_lteFalse_gasCostForEntireWord() public {
        setUpSomeTicks();

        snapStart("nextInitializedTickWithinOneWord_lteFalse_gasCostForEntireWord");
        tickBitmap.getGasCostOfNextInitializedTickWithinOneWord(768, false);
        snapEnd();
    }

    function test_nextInitializedTickWithinOneWord_lteTrue_returnsSameTickIfInitialized() public {
        setUpSomeTicks();

        (int24 next, bool initialized) = tickBitmap.nextInitializedTickWithinOneWord(78, true);

        assertEq(next, 78);
        assertEq(initialized, true);
    }

    function test_nextInitializedTickWithinOneWord_lteTrue_returnsTickDirectlyToTheLeftOfInputTickIfNotInitialized()
        public
    {
        setUpSomeTicks();

        (int24 next, bool initialized) = tickBitmap.nextInitializedTickWithinOneWord(79, true);

        assertEq(next, 78);
        assertEq(initialized, true);
    }

    function test_nextInitializedTickWithinOneWord_lteTrue_willNotExceedTheWordBoundary() public {
        setUpSomeTicks();

        (int24 next, bool initialized) = tickBitmap.nextInitializedTickWithinOneWord(258, true);

        assertEq(next, 256);
        assertEq(initialized, false);
    }

    function test_nextInitializedTickWithinOneWord_lteTrue_atTheWordBoundary() public {
        setUpSomeTicks();

        (int24 next, bool initialized) = tickBitmap.nextInitializedTickWithinOneWord(256, true);

        assertEq(next, 256);
        assertEq(initialized, false);
    }

    function test_nextInitializedTickWithinOneWord_lteTrue_wordBoundaryLess1nextInitializedTickInNextWord() public {
        setUpSomeTicks();

        (int24 next, bool initialized) = tickBitmap.nextInitializedTickWithinOneWord(72, true);

        assertEq(next, 70);
        assertEq(initialized, true);
    }

    function test_nextInitializedTickWithinOneWord_lteTrue_wordBoundary() public {
        setUpSomeTicks();

        (int24 next, bool initialized) = tickBitmap.nextInitializedTickWithinOneWord(-257, true);

        assertEq(next, -512);
        assertEq(initialized, false);
    }

    function test_nextInitializedTickWithinOneWord_lteTrue_entireEmptyWord() public {
        setUpSomeTicks();

        (int24 next, bool initialized) = tickBitmap.nextInitializedTickWithinOneWord(1023, true);

        assertEq(next, 768);
        assertEq(initialized, false);
    }

    function test_nextInitializedTickWithinOneWord_lteTrue_halfwayThroughEmptyWord() public {
        setUpSomeTicks();

        (int24 next, bool initialized) = tickBitmap.nextInitializedTickWithinOneWord(900, true);

        assertEq(next, 768);
        assertEq(initialized, false);
    }

    function test_nextInitializedTickWithinOneWord_lteTrue_boundaryIsInitialized() public {
        setUpSomeTicks();
        tickBitmap.flipTick(329);

        (int24 next, bool initialized) = tickBitmap.nextInitializedTickWithinOneWord(456, true);

        assertEq(next, 329);
        assertEq(initialized, true);
    }

    function test_nextInitializedTickWithinOneWord_lteTrue_gasCostOnBoundary() public {
        setUpSomeTicks();

        snapStart("nextInitializedTickWithinOneWord_lteTrue_gasCostOnBoundary");
        tickBitmap.getGasCostOfNextInitializedTickWithinOneWord(256, true);
        snapEnd();
    }

    function test_nextInitializedTickWithinOneWord_lteTrue_gasCostJustBelowBoundary() public {
        setUpSomeTicks();

        snapStart("nextInitializedTickWithinOneWord_lteTrue_gasCostJustBelowBoundary");
        tickBitmap.getGasCostOfNextInitializedTickWithinOneWord(255, true);
        snapEnd();
    }

    function test_nextInitializedTickWithinOneWord_lteTrue_gasCostForEntireWord() public {
        setUpSomeTicks();

        snapStart("nextInitializedTickWithinOneWord_lteTrue_gasCostForEntireWord");
        tickBitmap.getGasCostOfNextInitializedTickWithinOneWord(1024, true);
        snapEnd();
    }
}
