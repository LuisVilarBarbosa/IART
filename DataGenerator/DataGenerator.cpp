#include <algorithm>
#include <climits>
#include <ctime>
#include <fstream>
#include <iostream>
#include <set>
#include <string>
#include <vector>
#include "Node.h"

using namespace std;

bool fileExists(const string filename)
{
	ifstream in(filename);
	if (in.is_open()) {
		in.close();
		cout << "The indicated filename already exists.\n";
		return true;
	}
	return false;
}

int showAndGetNumber(string to_show, const int maxValue)
{
	string str;
	int value;
	do {
		cout << to_show;
		getline(cin, str);
		try {
			value = stoi(str);
		}
		catch (invalid_argument) {
			value = -1;
		}
		catch (out_of_range) {
			value = -1;
		}
		if (value < 0)
			cout << "Invalid value. It must be positive or zero.\n";
		if (value > maxValue)
			cout << "Value too large.\n";
	} while (value < 0);
	return (int)value;
}

vector<string> loadClientsFile(const string filename)
{
	vector<string> lines;
	ifstream in(filename);
	if (!in.is_open())
		cout << "Error opening the clients file.\n";
	string line;
	while (getline(in, line))
		if (!line.empty())
			lines.push_back(line);
	in.close();
	return lines;
}

void generateTrucks(ofstream &out, const int numTrucks)
{
	for (int id = 1; id <= numTrucks; id++) {
		int autonomy = (1 + rand() % 20) * 100;
		int maxLoad = 200 + rand() % 300;
		out << "camiao(" << id << ", " << autonomy << ", " << maxLoad << ").\n";
	}
}

double random(double min, double max)
{
	return (double)rand() / (RAND_MAX + 1)*(max - min) + min;
}

vector<Node> generateGraphPoints(ofstream &out, const int maxNumPoints, const int maxDegree)
{
	set<Node> graphPointsSet;
	for (int id = 1; id <= maxNumPoints; id++) {
		double longitude = random(0, maxDegree);
		double latitude = random(0, maxDegree);
		graphPointsSet.insert(Node(longitude, latitude));
	}
	vector<Node> graphPoints;
	graphPoints.assign(graphPointsSet.begin(), graphPointsSet.end());
	for (size_t id = 1; id <= graphPoints.size(); id++) {
		Node node = graphPoints[id - 1];
		out << "pontoGrafo(" << id << ", " << node.getLongitude() << ", " << node.getLatitude() << ").\n";
	}
	return graphPoints;
}

void generateInitialPoint(ofstream &out, const int inicialPoint, const int numPoints)
{
	int myInitialPoint;
	if (0 == inicialPoint)
		myInitialPoint = 1 + rand() % numPoints;
	else
		myInitialPoint = inicialPoint;
	out << "pontoInicial(" << myInitialPoint << ").\n";
}

void generateEndPoint(ofstream &out, const int endPoint, const int numPoints)
{
	int myEndPoint;
	if (0 == endPoint)
		myEndPoint = 1 + rand() % numPoints;
	else
		myEndPoint = endPoint;
	out << "pontoFinal(" << myEndPoint << ").\n";
}

void generateSupplyPoints(ofstream &out, const int maxNumSupplyPoints, const int numPoints)
{
	set<int> supplyPointsSet;
	for (int i = 0; i < maxNumSupplyPoints; i++) {
		int supplyPoint = 1 + rand() % numPoints;
		supplyPointsSet.insert(supplyPoint);
	}
	vector<int> supplyPoints;
	supplyPoints.assign(supplyPointsSet.begin(), supplyPointsSet.end());
	for (size_t i = 0; i < supplyPoints.size(); i++)
		out << "pontoAbastecimento(" << supplyPoints[i] << ").\n";
}

void generateOrders(ofstream &out, const int numOrders, const int numPoints, const vector<string> clients)
{
	for (int id = 1; id <= numOrders; id++) {
		double volume = random(0, 50);
		double value = random(1, 2500);
		int deliveryPointId = 1 + rand() % numPoints;
		string client = clients[rand() % clients.size()];
		out << "encomenda(" << id << ", " << volume << ", " << value << ", " << deliveryPointId << ", '" << client << "').\n";
	}
}

double degreesToKm(const double degrees)
{
	return 40000 * degrees / 360;
}

double calculate_cost(const Node n1, const Node n2)
{
	double diffLongitude = abs(n1.getLongitude() - n2.getLongitude());
	double diffLatitude = abs(n1.getLatitude() - n2.getLatitude());
	double hypotenuse = sqrt(diffLongitude * diffLongitude + diffLatitude * diffLatitude); // For better measurement, it should calculate arc instead of the line.
	return degreesToKm(hypotenuse);
}

// It is assumed that 'graphPoints' is ordered.
void generateSuccessors(ofstream &out, const int maxNumSuccessorsPerPoint, const vector<Node> graphPoints)
{
	int myMaxNumSuccessorsPerPoint;
	if (0 == maxNumSuccessorsPerPoint)
		myMaxNumSuccessorsPerPoint = 1 + rand() % 5;
	else
		myMaxNumSuccessorsPerPoint = maxNumSuccessorsPerPoint;

	size_t numPoints = graphPoints.size();
	for (size_t graphPointId = 1; graphPointId <= numPoints; graphPointId++) {
		int myMaxNumSuccessors = 1 + rand() % myMaxNumSuccessorsPerPoint;
		set<int> mySuccessorsSet;
		for (int i = 0; i < myMaxNumSuccessors; i++) {
			size_t successorId = 1 + (graphPointId - 1 + rand() % 5) % numPoints;
			if (successorId != graphPointId)
				mySuccessorsSet.insert(successorId);
		}
		vector<int> mySuccessors;
		mySuccessors.assign(mySuccessorsSet.begin(), mySuccessorsSet.end());
		for (size_t i = 0; i < mySuccessors.size(); i++) {
			int successorId = mySuccessors[i];
			Node n1 = graphPoints[graphPointId - 1];
			Node n2 = graphPoints[successorId - 1];
			double cost = calculate_cost(n1, n2);
			out << "sucessor(" << graphPointId << ", " << successorId << ", " << cost << ").\n";
			out << "sucessor(" << successorId << ", " << graphPointId << ", " << cost << ").\n";
		}
	}
}

void error()
{
	cout << "Press any key to continue . . .\n";
	getchar();
}

int main()
{
	srand((unsigned)time(NULL));
	string clientsFilename, outputFilename;

	cout << "Clients filename: ";
	getline(cin, clientsFilename);
	vector<string> clients = loadClientsFile(clientsFilename);
	if (clients.empty()) {
		cout << "No clients found.\n";
		error();
		return -1;
	}

	cout << "Output filename: ";
	getline(cin, outputFilename);
	if (fileExists(outputFilename)) {
		error();
		return -2;
	}

	ofstream out(outputFilename);
	if (!out.is_open()) {
		cout << "Error creating the output file.\n";
		error();
		return -3;
	}

	int numTrucks = showAndGetNumber("Number of trucks: ", INT_MAX);
	generateTrucks(out, numTrucks);
	out << "\n";
	int maxNumPoints = showAndGetNumber("Maximum number of graph points: ", INT_MAX);
	int maxDegree = showAndGetNumber("Maximum longitude and latitude degree: ", 360);
	vector<Node> graphPoints = generateGraphPoints(out, maxNumPoints, maxDegree);
	out << "\n";
	int numPoints = graphPoints.size();
	int initialPoint = showAndGetNumber("Inicial point (0 = random): ", numPoints);
	generateInitialPoint(out, initialPoint, numPoints);
	int endPoint = showAndGetNumber("End point (0 = random): ", numPoints);
	generateEndPoint(out, endPoint, numPoints);
	out << "\n";
	int maxNumSupplyPoints = showAndGetNumber("Maximum number of supply points: ", numPoints);
	generateSupplyPoints(out, maxNumSupplyPoints, numPoints);
	out << "\n";
	int numOrders = showAndGetNumber("Number of orders: ", numPoints);
	generateOrders(out, numOrders, numPoints, clients);
	out << "\n";
	int maxNumSuccessorsPerPoint = showAndGetNumber("Maximum number of successors per graph point (0 = default -> 5): ", numPoints);
	generateSuccessors(out, maxNumSuccessorsPerPoint, graphPoints);
	cout << "Completed.\n";

	out.close();
	return 0;
}
