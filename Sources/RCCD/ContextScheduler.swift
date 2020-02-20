import Foundation
import RxSwift
import CoreData

public final class ContextScheduler: ImmediateSchedulerType {
    private let context: NSManagedObjectContext

    public init(context: NSManagedObjectContext) {
        self.context = context
    }

    public func schedule<StateType>(_ state: StateType, action: @escaping (StateType) -> Disposable) -> Disposable {

        let disposable = SingleAssignmentDisposable()

        context.perform {
            if disposable.isDisposed {
                return
            }
            disposable.setDisposable(action(state))
        }

        return disposable
    }
}
