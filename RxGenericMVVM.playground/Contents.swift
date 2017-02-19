//: Simple MVVM example using generics (binding with RxSwift)

import UIKit
import RxCocoa
import RxSwift
import PlaygroundSupport

//: Protocol Definitions
protocol Model { }

protocol ViewModel {
    associatedtype T: Model
    init(model: T)
}

protocol View {
    associatedtype T: ViewModel
    init(viewModel: T)
}

//: Model Implementation
struct Person: Model {
    let title: String
    let firstName: String
    let lastName: String
    
    let address: String
    let city: String
    let postcode: String
    let country: String
}

//: Data Provider
class PersonProvider {
    private let people: [Person]
    
    init(people: [Person]) {
        self.people = people
    }
    
    private var index: Int = 0
    
    var current: Person {
        return people[index]
    }
    
    var next: Person {
        index = (index + 1) % people.count
        return current
    }
}

//: View Model Implementation
struct PersonViewModel: ViewModel {
    typealias T = Person
    private let model: Variable<T>
    private var provider: PersonProvider!
    
    let title: String = "Person Details"
    
    let nameHeading: String = "Name"
    let name: Observable<String>
    
    let addressHeading: String = "Address"
    let address: Observable<String>
    
    init(model: T) {
        self.model = Variable<T>(model)
        
        name = self.model.asObservable()
            .map { "\($0.title) \($0.firstName) \($0.lastName)" }
        
        address = self.model.asObservable()
            .map ({ "\($0.address)\n\($0.city)\n\($0.postcode)\n\($0.country)" })
    }
    
    init(provider: PersonProvider) {
        self.init(model: provider.current)
        self.provider = provider
    }
    
    func nextPerson() {
        model.value = provider.next
    }
}

//: View Implementation
let padding: CGFloat = 20

final class PersonView: UIView, View {
    typealias T = PersonViewModel
    private let viewModel: T
    
    // This logic should be moved to a styling file
    private static func makeAttributedHeading(_ heading: String, text: String) -> NSAttributedString {
        let attr = NSMutableAttributedString(string: "\(heading):\n", attributes: [NSFontAttributeName: UIFont.boldSystemFont(ofSize: 18)])
        attr.append(NSAttributedString(string: text, attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 16)]))
        return attr.copy() as! NSAttributedString
    }
    
    private static func makeLabel() -> UILabel {
        let label = UILabel(frame: .zero)
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }
    
    private let nameLabel: UILabel =  PersonView.makeLabel()
    private let addressLabel: UILabel = PersonView.makeLabel()
    
    private let disposeBag = DisposeBag()
    
    init(viewModel: T) {
        self.viewModel = viewModel
        super.init(frame: .zero)
        
        viewModel.name
            .map({ PersonView.makeAttributedHeading(viewModel.nameHeading, text: $0) })
            .bindTo(nameLabel.rx.attributedText)
            .addDisposableTo(disposeBag)
        
        viewModel.address
            .map({ PersonView.makeAttributedHeading(viewModel.addressHeading, text: $0) })
            .bindTo(addressLabel.rx.attributedText)
            .addDisposableTo(disposeBag)
        
        [nameLabel, addressLabel].forEach(addSubview)
        
        NSLayoutConstraint.activate([
            nameLabel.topAnchor.constraint(equalTo: topAnchor),
            nameLabel.leftAnchor.constraint(equalTo: leftAnchor),
            nameLabel.rightAnchor.constraint(equalTo: rightAnchor),
            
            addressLabel.leftAnchor.constraint(equalTo: nameLabel.leftAnchor),
            addressLabel.rightAnchor.constraint(equalTo: nameLabel.rightAnchor),
            addressLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: padding),
        ])
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

//: ViewController Implementation
final class PersonViewController: UIViewController, View {
    typealias T = PersonViewModel
    private let viewModel: PersonViewModel
    private let personView: PersonView
    private let nextButton: UIButton = {
        let button = UIButton(type: .roundedRect)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.layer.borderWidth = 1
        button.setTitleColor(.black, for: .normal)
        button.setTitle("Next Person", for: .normal)
        return button
    }()
    
    init(viewModel: T) {
        self.viewModel = viewModel
        self.personView = PersonView(viewModel: viewModel)
        self.personView.translatesAutoresizingMaskIntoConstraints = false
        super.init(nibName: nil, bundle: nil)
        
        view.backgroundColor = .white
        
        [personView, nextButton].forEach(view.addSubview)
        
        nextButton.addTarget(self, action: #selector(nextButtonPressed), for: .touchUpInside)
        
        title = viewModel.title
        
        NSLayoutConstraint.activate([
            nextButton.heightAnchor.constraint(equalToConstant: 40),
            nextButton.leftAnchor.constraint(equalTo: view.leftAnchor, constant: padding),
            nextButton.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -padding),
            nextButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -padding),
            
            personView.topAnchor.constraint(equalTo: view.topAnchor, constant: padding),
            personView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: padding),
            personView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -padding),
            personView.bottomAnchor.constraint(equalTo: nextButton.topAnchor, constant: -padding)
        ])
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func nextButtonPressed(sender: UIButton) {
        viewModel.nextPerson()
    }
}

//: Example PersonViewController embedded in a UINavigationController
let personProvider = PersonProvider(people: [
    Person(title: "Mrs", firstName: "Theresa", lastName: "May", address: "8 Downing Street", city: "London", postcode: "SW1A 2AA", country: "United Kingdom"),
    Person(title: "Mr", firstName: "Donald", lastName: "Trump", address: "The White House, 1600 Pennsylvania Avenue NW", city: "Washington, DC", postcode: "20500", country: "United States of America"),
    Person(title: "Mr", firstName: "Malcolm", lastName: "Turnbull", address: "Parliament House", city: "Canberra, ACT", postcode: "2600", country: "Australia")
    ])
let personViewModel = PersonViewModel(provider: personProvider)
let personViewController = PersonViewController(viewModel: personViewModel)
let navigationController = UINavigationController(rootViewController: personViewController)

personViewController.edgesForExtendedLayout = []
navigationController.view.frame = CGRect(origin: .zero, size: CGSize(width: 320, height: 480))

PlaygroundPage.current.liveView = navigationController.view
