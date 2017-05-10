#include "Node.h"

Node::Node(int longitude, int latitude) {
	this->longitude = longitude;
	this->latitude = latitude;
}

int Node::getLongitude() const {
	return longitude;
}

int Node::getLatitude() const {
	return latitude;
}

bool Node::operator<(const Node node) const {
	if (this->longitude < node.longitude)
		return true;
	else if (this->longitude == node.longitude)
		return this->latitude < node.latitude;
	return false;
}
