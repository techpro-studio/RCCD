import Foundation
import CoreData
import RxSwift




extension BaseCoreDataRepository {

    func subscribeFor(fetchRequest: NSFetchRequest<T.CoreDataType>,
                       sectionNameKeyPath: String? = nil,
                       cacheName: String? = nil) -> Observable<[T]> {
         return Observable.create { observer in

            let observerAdapter = FetchedResultsControllerEntityObserver(observer: observer, fetchRequest: fetchRequest, managedObjectContext: self.managedObjectContext, sectionNameKeyPath: sectionNameKeyPath, cacheName: cacheName)

             return Disposables.create {
                 observerAdapter.dispose()
             }
         }
    }

}


private final class FetchedResultsControllerEntityObserver<T: CDRepresentable> : NSObject, NSFetchedResultsControllerDelegate, Disposable where T.CoreDataType.DomainType == T {

    typealias Observer = AnyObserver<[T]>

    fileprivate let observer: Observer
    fileprivate let disposeBag = DisposeBag()
    fileprivate let frc: NSFetchedResultsController<T.CoreDataType>

    init(observer: Observer, fetchRequest: NSFetchRequest<T.CoreDataType>, managedObjectContext context: NSManagedObjectContext, sectionNameKeyPath: String?, cacheName: String?) {
        self.observer = observer


        self.frc = NSFetchedResultsController(fetchRequest: fetchRequest,
                                              managedObjectContext: context,
                                              sectionNameKeyPath: sectionNameKeyPath,
                                              cacheName: cacheName)
        super.init()

        context.perform {
            self.frc.delegate = self

            do {
                try self.frc.performFetch()
            } catch let e {
                observer.on(.error(e))
            }

            self.sendNextElement()
        }
    }

    fileprivate func sendNextElement() {
        self.frc.managedObjectContext.perform {
            let entities = (self.frc.fetchedObjects ?? []).map { $0.asDomain()}
            self.observer.on(.next(entities))
        }
    }

    public func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        sendNextElement()
    }

    public func dispose() {
        frc.delegate = nil
    }
}


