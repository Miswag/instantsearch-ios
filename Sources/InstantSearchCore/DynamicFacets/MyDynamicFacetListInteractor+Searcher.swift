//
//  DynamicFacetListInteractor+Searcher.swift
//  
//
//  Created by Vladislav Fitc on 16/03/2021.
//

import Foundation

public extension MyDynamicFacetListInteractor {
	
	/// Connection between a dynamic facets business logic and a searcher
	struct SearcherConnection<Searcher: SearchResultObservable>: Connection where Searcher.SearchResult == MultiSearchResponse {
		
		/// Dynamic facet list business logic
		public let interactor: MyDynamicFacetListInteractor
		
		/// Searcher that handles your searches
		public let searcher: Searcher
		
		/**
		 - parameters:
		 - interactor: Dynamic facet list business logic
		 - searcher: Searcher to connect
		 */
		public init(interactor: MyDynamicFacetListInteractor,
					searcher: Searcher) {
			self.searcher = searcher
			self.interactor = interactor
		}
		
		public func connect() {
			searcher.onResults.subscribe(with: interactor) { (interactor, searchResponse) in
				
				if let facetOrdering = searchResponse.results.first?.hitsResponse?.renderingContent?.facetOrdering,
				   let facets = searchResponse.facets {
					interactor.orderedFacets = FacetsOrderer(facetOrder: facetOrdering, facets: facets)()
				} else {
					interactor.orderedFacets = []
				}
				
				
			}
			(searcher as? ErrorObservable)?.onError.subscribe(with: interactor) { interactor, _ in
				interactor.orderedFacets = []
			}
		}
		
		public func disconnect() {
			searcher.onResults.cancelSubscription(for: interactor)
			(searcher as? ErrorObservable)?.onError.cancelSubscription(for: interactor)
		}
	}
	
	/**
	 Establishes connection with a Searcher
	 - parameter searcher: searcher to connect
	 */
	@discardableResult func connectSearcher<Searcher: SearchResultObservable>(_ searcher: Searcher) -> SearcherConnection<Searcher> {
		let connection = SearcherConnection(interactor: self, searcher: searcher)
		connection.connect()
		return connection
	}
	
}

extension MultiSearchResponse {
	var facets:[Attribute: [Facet]]? {
		return results.first?.hitsResponse?.facets
		
	}
}
