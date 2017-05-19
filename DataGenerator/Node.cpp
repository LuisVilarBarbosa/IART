#include "Node.h"

Node::Node(double longitude, double latitude) {
	this->longitude = longitude;
	this->latitude = latitude;
}

double Node::getLongitude() const {
	return longitude;
}

double Node::getLatitude() const {
	return latitude;
}

bool Node::operator<(const Node node) const {
	if (this->longitude < node.longitude)
		return true;
	else if (this->longitude == node.longitude)
		return this->latitude < node.latitude;
	return false;
}
