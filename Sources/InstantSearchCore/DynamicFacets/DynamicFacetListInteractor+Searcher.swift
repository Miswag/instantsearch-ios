//
//  DynamicFacetListInteractor+Searcher.swift
//  
//
//  Created by Vladislav Fitc on 16/03/2021.
//

import Foundation

public extension DynamicFacetListInteractor {
	
	/// Connection between a dynamic facets business logic and a searcher
	struct SearcherConnection<Searcher: SearchResultObservable>: Connection where Searcher.SearchResult == SearchResponse {
		
		/// Dynamic facet list business logic
		public let interactor: DynamicFacetListInteractor
		
		/// Searcher that handles your searches
		public let searcher: Searcher
		
		var isDisjunctiveFacetingEnabled: Bool
		
		/**
		 - parameters:
		 - interactor: Dynamic facet list business logic
		 - searcher: Searcher to connect
		 - showDisjunctiveFacets: Set true to list disjunctive facets in orderedFacets
		 */
		public init(interactor: DynamicFacetListInteractor,
					searcher: Searcher,
					isDisjunctiveFacetingEnabled:Bool) {
			self.searcher = searcher
			self.interactor = interactor
			self.isDisjunctiveFacetingEnabled = isDisjunctiveFacetingEnabled
		}
		
		public func connect() {
			searcher.onResults.subscribe(with: interactor) { (interactor, searchResponse) in
				if let facetOrdering = searchResponse.renderingContent?.facetOrdering,
				   var facets = searchResponse.facets {
					//debugPrint(facets)
					if isDisjunctiveFacetingEnabled {
						if let disjuctiveFacets = searchResponse.disjunctiveFacets {
							disjuctiveFacets.forEach({ (key:Attribute,value:[Facet]) in
								value.forEach { facet in
									if let attributeFacets = facets[key] {
										if !attributeFacets.contains(where: {$0.value == facet.value}) {
											facets[key]?.append(facet)
											//debugPrint(facet)
										}
									}
								}
							})
						}
					}
					
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
		let connection = SearcherConnection(interactor: self,
											searcher: searcher,
											isDisjunctiveFacetingEnabled: isDisjunctiveFacetingEnabled)
		connection.connect()
		return connection
	}
	
}
