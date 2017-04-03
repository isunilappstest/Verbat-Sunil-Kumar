
import UIKit
import QuartzCore

//MARK: - Protocol Declarations
//MARK: CubeController DataSource
protocol CubeControllerDataSource : NSObjectProtocol {
    
    func numberOfViewControllersInCubeController(cubeController : CubeController!) -> NSInteger
    func cubeController(cubeController : CubeController!, viewControllerAtIndex index : Int ) -> UIViewController!
}

//MARK: - CubeController Class
class CubeController : UIViewController, UIScrollViewDelegate {
    
    //MARK: Variables Declaration
    private(set) var scrollView01 : UIScrollView = UIScrollView()
    private(set) var numberOfViewControllers : NSInteger = NSInteger()
    private(set) var currentViewControllerIndex : NSInteger = NSInteger()
    private(set) var wrapEnabled : Bool = Bool()
    
    private(set) var controllers : NSMutableDictionary = NSMutableDictionary()
    private(set) var scrollOffset : CGFloat = CGFloat()
    private(set) var previousOffset : CGFloat = CGFloat()
    
    //MARK: Protocol Variables
    internal(set) var dataSource : CubeControllerDataSource?
    
    //MARK: View Related
    override func viewDidLoad() {
        
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        wrapEnabled = true//if true enables the wrapping ViewControllers
        
        //Adding ScrollView
        self.scrollView01 = UIScrollView(frame: self.isViewLoaded() ? self.view.bounds : UIScreen.mainScreen().bounds)
        self.scrollView01.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        self.scrollView01.pagingEnabled = true
        self.scrollView01.directionalLockEnabled = true
        self.scrollView01.autoresizesSubviews = false
        self.scrollView01.showsHorizontalScrollIndicator = false
        self.scrollView01.showsVerticalScrollIndicator = false
        self.scrollView01.delegate = self
        self.view.addSubview(self.scrollView01)
        
        self.reloadData()
    }
    
    override func viewDidLayoutSubviews() {
        
        super.viewDidLayoutSubviews()
        
        var pages = numberOfViewControllers
        
        if wrapEnabled && numberOfViewControllers > 1  {
            
            pages += 2
        }
        
        scrollView01.contentSize = CGSizeMake(self.view.bounds.size.width * CGFloat(pages), self.view.bounds.size.height)
        
        self.updateContentOffset()
        self.loadUnloadControllers()
        self.updateLayout()
        self.updateInteraction()
    }
    
    //MARK: ViewController Related Methods
    func reloadData() {
        
        self.numberOfViewControllers = (self.dataSource?.numberOfViewControllersInCubeController(self))!
    }
    
    func updateContentOffset() {
        
        scrollView01.contentOffset = CGPointMake(self.view.bounds.size.width * scrollOffset, 0.0)
    }
    
    func loadUnloadControllers() {
        
        //calculate visible indices
        let visibleIndices : NSMutableSet = NSMutableSet.init(object: currentViewControllerIndex)
        
        if wrapEnabled || (currentViewControllerIndex < (numberOfViewControllers - 1)) {
            
            visibleIndices.addObject(currentViewControllerIndex + 1)
        }
        
        if currentViewControllerIndex > 0 {
            
            visibleIndices.addObject(currentViewControllerIndex - 1)
            
        } else if wrapEnabled {
            
            visibleIndices.addObject(-1)
        }
        
        //remove hidden controllers
        for index in controllers.allKeys {
            
            if !visibleIndices.containsObject(index) {
                
                let controller = controllers[index as! NSCopying]
                
                controller?.view.removeFromSuperview()
                controller?.removeFromParentViewController()
                controllers.removeObjectForKey(index)
            }
        }
        
        //load Controllers
        for index in visibleIndices {
            
            var controller = controllers[index as! NSCopying]
            
            if (controller == nil) && Bool(numberOfViewControllers) {
                
                controller = self.dataSource?.cubeController(self, viewControllerAtIndex: (index.integerValue + numberOfViewControllers) % numberOfViewControllers)
                controllers[index as! NSCopying] = controller
            }
        }
    }
    
    func updateLayout() {
        
        for index in controllers.allKeys {
            
            let controller = controllers[index as! NSCopying]
            
            if (controller != nil) && !(controller?.parentViewController == controller as? UIViewController) {
                
                controller?.view.autoresizingMask = .None
                controller?.view.layer.doubleSided = false
                
                self.addChildViewController(controller as! UIViewController)
                
                scrollView01.addSubview((controller?.view)!)
            }
            
            var angle = CGFloat(Double(scrollOffset - CGFloat(index.integerValue)) * M_PI_2)
            
            while (angle < 0) {
                
                angle += CGFloat(M_PI * 2);
            }
            
            while (angle > CGFloat(M_PI * 2)) {
                
                angle -= CGFloat(M_PI * 2);
            }
            
            var transform = CATransform3DIdentity
            
            if angle != 0.0 {
                
                transform.m34 = -1.0/500;
                transform = CATransform3DTranslate(transform, 0, 0, -self.view.bounds.size.width / 2.0);
                transform = CATransform3DRotate(transform, -angle, 0, 1, 0);
                transform = CATransform3DTranslate(transform, 0, 0, self.view.bounds.size.width / 2.0)
            }
            
            controller?.view.bounds = self.view.bounds
            controller?.view.center = CGPointMake(self.view.bounds.size.width / 2.0 + scrollView01.contentOffset.x, self.view.bounds.size.height / 2.0)
            controller?.view.layer.transform = transform
        }
    }
    
    func updateInteraction() {
        
        for index in controllers.allKeys {
            
            (controllers[index as! NSCopying] as! UIViewController).view.userInteractionEnabled = (index.integerValue == currentViewControllerIndex)
        }
    }
    
    //MARK: ScrollView Related Methods
    func scrollViewDidScroll(scrollView: UIScrollView) {
        
        //update scroll offset
        let offset = scrollView01.contentOffset.x / self.view.bounds.size.width
        
        scrollOffset += (offset - previousOffset)
        
        if wrapEnabled {
            
            while (scrollOffset < 0.0) {
                
                scrollOffset += CGFloat(numberOfViewControllers);
            }
            
            while (scrollOffset >= CGFloat(numberOfViewControllers)) {
                
                scrollOffset -= CGFloat(numberOfViewControllers);
            }
        }
        
        previousOffset = offset
        
        //prevent error accumulation
        if (offset - floor(offset) == 0.0) {
            
            scrollOffset = round(scrollOffset);
        }
        
        //update index
        currentViewControllerIndex = max(0, min(numberOfViewControllers - 1, NSInteger((round(scrollOffset)))))
        
        //update content
        self.updateContentOffset()
        self.loadUnloadControllers()
        self.updateLayout()
        
        //enable/disable interaction
        self.updateInteraction()
    }
}