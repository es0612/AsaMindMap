import Foundation
import Testing
@testable import MindMapCore

struct TemplateUseCaseTests {
    
    @Test("テンプレート作成ユースケース")
    func testCreateTemplateUseCase() async throws {
        // Given
        let mockRepository = MockTemplateRepository()
        let useCase = CreateTemplateUseCase(repository: mockRepository)
        
        let request = CreateTemplateRequest(
            title: "プロジェクト計画",
            description: "新規プロジェクトの計画立案用テンプレート",
            category: .business,
            isPreset: false
        )
        
        // When
        let response = try await useCase.execute(request)
        
        // Then
        #expect(response.template.title == request.title)
        #expect(response.template.description == request.description)
        #expect(response.template.category == request.category)
        #expect(response.template.isPreset == request.isPreset)
        #expect(mockRepository.saveCallCount == 1)
    }
    
    @Test("テンプレート一覧取得ユースケース")
    func testFetchTemplatesUseCase() async throws {
        // Given
        let mockRepository = MockTemplateRepository()
        mockRepository.setupTemplates()
        let useCase = FetchTemplatesUseCase(repository: mockRepository)
        
        let request = FetchTemplatesRequest(
            category: .business,
            includePresets: true,
            sortBy: .createdDate
        )
        
        // When
        let response = try await useCase.execute(request)
        
        // Then
        #expect(response.templates.count > 0)
        #expect(response.templates.allSatisfy { $0.category == .business })
        #expect(mockRepository.fetchCallCount == 1)
    }
    
    @Test("テンプレート適用ユースケース")
    func testApplyTemplateUseCase() async throws {
        // Given
        let mockTemplateRepository = MockTemplateRepository()
        let mockMindMapRepository = MockMindMapRepository()
        
        let useCase = ApplyTemplateUseCase(
            templateRepository: mockTemplateRepository,
            mindMapRepository: mockMindMapRepository
        )
        
        // テンプレートをセットアップ
        let template = Template(
            title: "ブレインストーミング",
            description: "アイデア発想用テンプレート",
            category: .creative,
            isPreset: true
        )
        mockTemplateRepository.templates[template.id] = template
        
        let request = ApplyTemplateRequest(
            templateId: template.id,
            mindMapTitle: "新商品アイデア",
            placeholderReplacements: [:]
        )
        
        // When
        let response = try await useCase.execute(request)
        
        // Then
        #expect(response.mindMap.title == "新商品アイデア")
        #expect(response.mindMap.templateId == template.id)
        #expect(mockMindMapRepository.saveCallCount == 1)
    }
    
    @Test("テンプレート更新ユースケース")
    func testUpdateTemplateUseCase() async throws {
        // Given
        let mockRepository = MockTemplateRepository()
        let useCase = UpdateTemplateUseCase(repository: mockRepository)
        
        // 既存テンプレートをセットアップ
        let existingTemplate = Template(
            title: "既存テンプレート",
            description: "元の説明",
            category: .personal,
            isPreset: false
        )
        mockRepository.templates[existingTemplate.id] = existingTemplate
        
        let request = UpdateTemplateRequest(
            templateId: existingTemplate.id,
            title: "更新されたテンプレート",
            description: "新しい説明",
            category: .business
        )
        
        // When
        let response = try await useCase.execute(request)
        
        // Then
        #expect(response.template.title == request.title)
        #expect(response.template.description == request.description)
        #expect(response.template.category == request.category)
        #expect(mockRepository.updateCallCount == 1)
    }
    
    @Test("テンプレート削除ユースケース")
    func testDeleteTemplateUseCase() async throws {
        // Given
        let mockRepository = MockTemplateRepository()
        let useCase = DeleteTemplateUseCase(repository: mockRepository)
        
        // テンプレートをセットアップ
        let template = Template(
            title: "削除対象テンプレート",
            description: "削除されるテンプレート",
            category: .personal,
            isPreset: false
        )
        mockRepository.templates[template.id] = template
        
        let request = DeleteTemplateRequest(templateId: template.id)
        
        // When
        let response = try await useCase.execute(request)
        
        // Then
        #expect(response.success == true)
        #expect(mockRepository.deleteCallCount == 1)
    }
    
    @Test("プリセットテンプレート削除の拒否")
    func testPresetTemplateDeletionRejection() async throws {
        // Given
        let mockRepository = MockTemplateRepository()
        let useCase = DeleteTemplateUseCase(repository: mockRepository)
        
        // プリセットテンプレートをセットアップ
        let presetTemplate = Template(
            title: "プリセットテンプレート",
            description: "システム提供テンプレート",
            category: .business,
            isPreset: true
        )
        mockRepository.templates[presetTemplate.id] = presetTemplate
        
        let request = DeleteTemplateRequest(templateId: presetTemplate.id)
        
        // When & Then
        await #expect(throws: TemplateError.cannotDeletePreset) {
            try await useCase.execute(request)
        }
    }
    
    @Test("テンプレート複製ユースケース")
    func testDuplicateTemplateUseCase() async throws {
        // Given
        let mockRepository = MockTemplateRepository()
        let useCase = DuplicateTemplateUseCase(repository: mockRepository)
        
        // 元テンプレートをセットアップ
        let originalTemplate = Template(
            title: "元テンプレート",
            description: "複製元の説明",
            category: .education,
            isPreset: false
        )
        mockRepository.templates[originalTemplate.id] = originalTemplate
        
        let request = DuplicateTemplateRequest(
            templateId: originalTemplate.id,
            newTitle: "複製されたテンプレート"
        )
        
        // When
        let response = try await useCase.execute(request)
        
        // Then
        #expect(response.template.title == "複製されたテンプレート")
        #expect(response.template.description == originalTemplate.description)
        #expect(response.template.category == originalTemplate.category)
        #expect(response.template.isPreset == false) // 複製は常にカスタム
        #expect(response.template.id != originalTemplate.id)
        #expect(mockRepository.saveCallCount == 1)
    }
}