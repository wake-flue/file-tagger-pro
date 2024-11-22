#include "tag.h"

Tag::Tag(QObject *parent)
    : QObject(parent)
    , m_id(-1)
    , m_color(Qt::blue)
{
} 