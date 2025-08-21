import Testing
import SwiftUI
@testable import MindMapUI
@testable import MindMapCore

@available(iOS 16.0, macOS 14.0, *)
struct ProgressIndicatorViewTests {
    
    // MARK: - Test Data
    private let sampleProgressData = ProgressData(total: 10, completed: 7)
    private let emptyProgressData = ProgressData(total: 0, completed: 0)
    private let completedProgressData = ProgressData(total: 5, completed: 5)
    
    // MARK: - ProgressData Tests
    
    @Test
    func testProgressDataInitialization() {
        let progress = ProgressData(total: 10, completed: 6)
        
        #expect(progress.total == 10)
        #expect(progress.completed == 6)
        #expect(progress.remaining == 4)
        #expect(progress.percentage == 60.0)
    }
    
    @Test
    func testProgressDataZeroTotal() {
        let progress = ProgressData(total: 0, completed: 0)
        
        #expect(progress.total == 0)
        #expect(progress.completed == 0)
        #expect(progress.remaining == 0)
        #expect(progress.percentage == 0.0)
    }
    
    @Test
    func testProgressDataCompletedExceedsTotal() {
        let progress = ProgressData(total: 5, completed: 10)
        
        #expect(progress.total == 5)
        #expect(progress.completed == 5) // Should be clamped to total
        #expect(progress.remaining == 0)
        #expect(progress.percentage == 100.0)
    }
    
    @Test
    func testProgressDataNegativeValues() {
        let progress = ProgressData(total: -5, completed: -2)
        
        #expect(progress.total == 0) // Should be clamped to 0
        #expect(progress.completed == 0) // Should be clamped to 0
        #expect(progress.percentage == 0.0)
    }
    
    @Test
    func testProgressDataFromUseCaseResponse() {
        let response = GetBranchProgressResponse(
            totalTasks: 8,
            completedTasks: 3,
            progressPercentage: 37.5
        )
        
        let progress = ProgressData(from: response)
        
        #expect(progress.total == 8)
        #expect(progress.completed == 3)
        #expect(progress.remaining == 5)
        #expect(progress.percentage == 37.5)
    }
    
    // MARK: - ProgressIndicatorView Tests
    
    @Test
    func testProgressIndicatorViewInitialization() {
        let progressView = ProgressIndicatorView(progress: sampleProgressData)
        
        #expect(progressView.progress.total == 10)
        #expect(progressView.progress.completed == 7)
        #expect(progressView.style == .circular)
        #expect(progressView.size == .medium)
        #expect(progressView.showDetails == false)
    }
    
    @Test
    func testProgressIndicatorViewWithCustomProperties() {
        var tapCalled = false
        
        let progressView = ProgressIndicatorView(
            progress: sampleProgressData,
            style: .linear,
            size: .large,
            showDetails: true,
            onTap: { tapCalled = true }
        )
        
        #expect(progressView.progress.total == 10)
        #expect(progressView.style == .linear)
        #expect(progressView.size == .large)
        #expect(progressView.showDetails == true)
    }
    
    // MARK: - ProgressSize Tests
    
    @Test
    func testProgressSizeProperties() {
        let smallSize = ProgressSize.small
        let mediumSize = ProgressSize.medium
        let largeSize = ProgressSize.large
        
        // Circular sizes
        #expect(smallSize.circularSize == 40)
        #expect(mediumSize.circularSize == 60)
        #expect(largeSize.circularSize == 80)
        
        // Linear widths
        #expect(smallSize.linearWidth == 80)
        #expect(mediumSize.linearWidth == 120)
        #expect(largeSize.linearWidth == 160)
        
        // Show center text
        #expect(smallSize.showCenterText == false)
        #expect(mediumSize.showCenterText == true)
        #expect(largeSize.showCenterText == true)
    }
    
    // MARK: - ProgressStyle Tests
    
    @Test
    func testProgressStyleTypes() {
        let circularStyle = ProgressStyle.circular
        let linearStyle = ProgressStyle.linear
        let ringStyle = ProgressStyle.ring
        let minimalStyle = ProgressStyle.minimal
        
        // Each style should be distinct
        #expect(circularStyle != linearStyle)
        #expect(ringStyle != minimalStyle)
    }
    
    // MARK: - BranchProgressView Tests
    
    @Test
    func testBranchProgressViewInitialization() {
        let nodeId = UUID()
        let branchView = BranchProgressView(nodeId: nodeId)
        
        #expect(branchView.nodeId == nodeId)
        #expect(branchView.progress == nil)
        #expect(branchView.style == .ring)
        #expect(branchView.size == .small)
        #expect(branchView.showWhenEmpty == false)
    }
    
    @Test
    func testBranchProgressViewWithProgress() {
        let nodeId = UUID()
        var tapCalled = false
        
        let branchView = BranchProgressView(
            nodeId: nodeId,
            progress: sampleProgressData,
            style: .circular,
            size: .medium,
            showWhenEmpty: true,
            onTap: { tapCalled = true }
        )
        
        #expect(branchView.nodeId == nodeId)
        #expect(branchView.progress?.total == 10)
        #expect(branchView.style == .circular)
        #expect(branchView.size == .medium)
        #expect(branchView.showWhenEmpty == true)
    }
    
    // MARK: - Edge Case Tests
    
    @Test
    func testProgressIndicatorViewWithEmptyProgress() {
        let progressView = ProgressIndicatorView(progress: emptyProgressData)
        
        #expect(progressView.progress.total == 0)
        #expect(progressView.progress.completed == 0)
        #expect(progressView.progress.percentage == 0.0)
    }
    
    @Test
    func testProgressIndicatorViewWithCompletedProgress() {
        let progressView = ProgressIndicatorView(progress: completedProgressData)
        
        #expect(progressView.progress.total == 5)
        #expect(progressView.progress.completed == 5)
        #expect(progressView.progress.percentage == 100.0)
    }
    
    // MARK: - Integration Tests
    
    @Test
    func testProgressDataCalculationConsistency() {
        let testCases = [
            (total: 10, completed: 0, expectedPercentage: 0.0),
            (total: 10, completed: 5, expectedPercentage: 50.0),
            (total: 10, completed: 10, expectedPercentage: 100.0),
            (total: 3, completed: 1, expectedPercentage: 33.333333333333336),
            (total: 7, completed: 2, expectedPercentage: 28.571428571428573)
        ]
        
        for testCase in testCases {
            let progress = ProgressData(total: testCase.total, completed: testCase.completed)
            #expect(abs(progress.percentage - testCase.expectedPercentage) < 0.000001)
        }
    }
    
    @Test
    func testBranchProgressViewShowWhenEmptyBehavior() {
        let nodeId = UUID()
        
        // Should show when showWhenEmpty is true, even with empty progress
        let showEmptyView = BranchProgressView(
            nodeId: nodeId,
            progress: emptyProgressData,
            showWhenEmpty: true
        )
        #expect(showEmptyView.showWhenEmpty == true)
        
        // Should not show when showWhenEmpty is false with empty progress
        let hideEmptyView = BranchProgressView(
            nodeId: nodeId,
            progress: emptyProgressData,
            showWhenEmpty: false
        )
        #expect(hideEmptyView.showWhenEmpty == false)
    }
}