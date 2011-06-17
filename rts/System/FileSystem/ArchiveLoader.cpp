/* This file is part of the Spring engine (GPL v2 or later), see LICENSE.html */

#include "StdAfx.h"
#include "mmgr.h"

#include "ArchiveLoader.h"

#include "ArchiveFactory.h"

#include "ArchiveBase.h"
#include "ArchivePool.h"
#include "ArchiveDir.h"
#include "ArchiveZip.h"
#include "Archive7Zip.h"

#include "FileSystem.h"

#include "Util.h"


CArchiveLoader::CArchiveLoader()
{
	// TODO maybe move ArchiveFactory registration to some external place
	AddFactory(new CPoolArchiveFactory());
	AddFactory(new CDirArchiveFactory());
	AddFactory(new CZipArchiveFactory());
	AddFactory(new CSevenZipArchiveFactory());
}

CArchiveLoader::~CArchiveLoader()
{
	std::map<std::string, IArchiveFactory*>::iterator afi;
	for (afi = archiveFactories.begin(); afi != archiveFactories.end(); ++afi) {
		SafeDelete(afi->second);
	}
}


CArchiveLoader& CArchiveLoader::GetInstance()
{
	static CArchiveLoader singleton;
	return singleton;
}


bool CArchiveLoader::IsArchiveFile(const std::string& fileName) const
{
	const std::string ext = filesystem.GetExtension(fileName);

	return (archiveFactories.find(ext) != archiveFactories.end());
}


CArchiveBase* CArchiveLoader::OpenArchive(const std::string& fileName, const std::string& type) const
{
	CArchiveBase* ret = NULL;

	const std::string ext = type.empty() ? filesystem.GetExtension(fileName) : type;
	const std::string filePath = filesystem.LocateFile(fileName);

	const std::map<std::string, IArchiveFactory*>::const_iterator afi
			= archiveFactories.find(ext);

	if (afi != archiveFactories.end()) {
		ret = afi->second->CreateArchive(filePath);
	}

	if (ret && ret->IsOpen()) {
		return ret;
	}

	delete ret;
	return NULL;
}


void CArchiveLoader::AddFactory(IArchiveFactory* archiveFactory)
{
	assert(archiveFactory != NULL);
	// ensure unique extensions
	assert(archiveFactories.find(archiveFactory->GetDefaultExtension()) == archiveFactories.end());

	archiveFactories[archiveFactory->GetDefaultExtension()] = archiveFactory;
}
