// TALHA

import UIKit
import SocketIO

// Struct for parsed JSON data ------------------------------------

struct NewsAPIStruct:Decodable
{
    let headlines:[Headlines];
}

struct Headlines:Decodable
{
    let newsgroupID:Int;
    let newsgroup: String;
    let headline: String;
    
    init (json: [String: Any])
    {
        newsgroupID = json ["newsgroupID"] as? Int ?? -1;
        newsgroup = json ["newsgroup"] as? String ?? "";
        headline = json ["headline"] as? String ?? "";
    };
};

// Struct end  --------------------------------------------------

class ViewController: UIViewController,UITableViewDelegate,UITableViewDataSource
{
    private var tableView:UITableView!;
    private var headlinesArray = [String]();
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return self.headlinesArray.count;
    };
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        print ( self.headlinesArray[indexPath.row])
        cell.textLabel?.text = self.headlinesArray[indexPath.row];
        return cell
    };
    
    // for making socket connection with token:zr and URL : LocalHost : 8080
    
    let manager = SocketManager(socketURL: URL(string: "http://localhost:8080")!,config: [.log(true),.connectParams(["token": "ABC438s"])])
    
    var socket:SocketIOClient!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        self.setTable();
        self.socket = manager.defaultSocket;
        self.setSocketEvents();
        
        self.socket.connect();
        self.getHeadlines();
    }
    private func setTable()
    {
        let displayWidth: CGFloat = self.view.frame.width;
        let displayHeight: CGFloat = self.view.frame.height;
        
        self.tableView = UITableView(frame: CGRect(x: 0, y:0, width: displayWidth, height: displayHeight));
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell");
        self.tableView.dataSource = self;
        self.tableView.delegate = self;
        self.view.addSubview(self.tableView);
    };
    
    func getHeadlines()
    {
        self.headlinesArray = [];
        
        let jsonURLString:String = "http://localhost:3000/headlines/?token=ABC438s";
        guard let url = URL(string: jsonURLString) else
        {return}
        
        URLSession.shared.dataTask(with: url) { (data, response, err) in
            
            guard let data = data else { return }
            
            do{
                let newsAPIStruct = try
                    JSONDecoder().decode(NewsAPIStruct.self, from: data)
                
                for item in newsAPIStruct.headlines
                {
                    self.headlinesArray.append (item.headline);
                };
                
                DispatchQueue.main.async(execute: {
                    self.tableView.reloadData()
                })
            } catch let jsonErr
            {
                print ("error: ", jsonErr)
            }
            }.resume();
    };
    
    private func setSocketEvents()
    {
        self.socket.on(clientEvent: .connect) {data, ack in
            print("socket connected");
        };
        
        self.socket.on("headlines_updated") {data, ack in
            self.getHeadlines();
        };
    };
    
    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    };
};

