#ifndef NODE_H
#define NODE_H

class Node {
private:
	int longitude;
	int latitude;
public:
	Node(int longitude, int latitude);
	int getLongitude() const;
	int getLatitude() const;
	bool operator<(const Node node) const;
};

#endif
