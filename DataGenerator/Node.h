#ifndef NODE_H
#define NODE_H

class Node {
private:
	double longitude;
	double latitude;
public:
	Node(double longitude, double latitude);
	double getLongitude() const;
	double getLatitude() const;
	bool operator<(const Node node) const;
};

#endif
