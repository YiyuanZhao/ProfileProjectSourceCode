# include <string>
// # include <list>
# include <deque>
# include <vector>
# include <fstream>
# include <iostream>
# include <iomanip>

using namespace std;

enum class MagmomType:char {
    Magnetic,
    NonMagnetic,
    Uninitialized
};


class DoscarProcessor
{
private:
    deque<double> projectedDOS;
    vector<double> totalDOS, mergedDOS;
    string location;
    size_t totDosNumber, projectedDosNumber, totPoints, totalAtomNumber;
    float energyMax, energyMin;
    double fermiLevel;

public:
    DoscarProcessor(MagmomType Magmom, string* const folderName) {
        string fileName ("\\..\\demoData\\DOSCAR");
        location = *folderName + fileName;
        switch (Magmom)
        {
        case MagmomType::Magnetic:
            totDosNumber = 4;
            projectedDosNumber = 18;
            break;

        case MagmomType::NonMagnetic:
            totDosNumber = 2;
            projectedDosNumber = 9;
            break;

        case MagmomType::Uninitialized:
            string err = "Magmom Type Not proper initialized, exiting";
            throw invalid_argument(err);
            exit(-1);
        }
        
        this->ReadDoscarFile();
    };

    int ReadDoscarFile() {
        int loopIndex = 1;
        int startReadLine = 6;
        double data;
        string lineContent;
        fstream instream(location, ios_base::in);
        instream >> totalAtomNumber;
        while (instream)
        {
            if (loopIndex >= startReadLine) break;
            getline(instream, lineContent, '\n');
            loopIndex++;
        };
        instream >> energyMax >> energyMin >> totPoints >> fermiLevel >> lineContent;
        instream.seekg(1, ios::cur);
        while (instream)
        {
            for (size_t pointIdx = 0; pointIdx < totPoints*(totDosNumber + 1); pointIdx++)
            {
                instream >> data;
                totalDOS.push_back(data);
            }
            instream.seekg(1, ios::cur);            
            getline(instream, lineContent, '\n');
            for (size_t atomIdx = 0; atomIdx < totalAtomNumber; atomIdx++)
            {
                for (size_t pointIdx = 0; pointIdx < totPoints*(projectedDosNumber + 1); pointIdx++)
                {
                    instream >> data;
                    projectedDOS.push_back(data);
                }
                instream.seekg(1, ios::cur);
                getline(instream, lineContent);
            }
                       
            cout << lineContent;
        }
        instream.close();
        return 0;
    };

    int MergeDoscarTable(){
        mergedDOS.reserve(totPoints*projectedDosNumber);
        for (size_t atomIdx = 0; atomIdx < totalAtomNumber; atomIdx++)
        {
            for (size_t kpointIdx = 0; kpointIdx < totPoints; kpointIdx++)
            {
                double data = projectedDOS.front();
                mergedDOS.push_back(data - fermiLevel);
                projectedDOS.pop_front();
                for (size_t orbitIdx = 0; orbitIdx < projectedDosNumber; orbitIdx++)
                {
                    data = projectedDOS.front();
                    mergedDOS.push_back(data);
                    projectedDOS.pop_front();
                }
                for (size_t orbitIdx = 1; orbitIdx < totDosNumber + 1; orbitIdx++)
                {
                    mergedDOS.push_back(totalDOS[kpointIdx*(totDosNumber+1) + orbitIdx]);
                }
            }
            
        }
        return 0;
    }

    int PrintMergedTable(const string* filename, const string* arguments) {
        ofstream outfile;
        outfile.open(*filename, ios::out | ios::app);
        for (int numIdx=0; numIdx<int(mergedDOS.size()); numIdx++)
        {
            int atomIdx = int(numIdx)/(totPoints*(totDosNumber + projectedDosNumber + 1)) + 1;
            if (numIdx % (totDosNumber + projectedDosNumber + 1) == 0)
            {
                if (numIdx != 0) {
                    outfile << endl;
                }
                outfile << arguments[1] << " " << arguments[2] << " " << arguments[3] << " " << arguments[4] << " " << atomIdx << " " << mergedDOS[numIdx];
            }
            else    
                outfile << " " << mergedDOS[numIdx];
        }
        outfile << endl;
        outfile.close();
        return 0;
    }

    ~DoscarProcessor() {
        // cout << "Destructor called" << endl;
    };
};


// kpointsGenerator::kpointsGenerator(/* args */)
// {
// }

// kpointsGenerator::~kpointsGenerator()
// {
// }

int main(int argc, char const *argv[]) {
    // The arguments should be "Material" "CellType" "Distance" "MagConfig", these arguments will be insert into the front of data.
    // e.g. VSe2, Primary, 3.12, FM
    string location (".");
    string outFileName ("processedDoscar.dat");
    string outParameter[5];
    MagmomType magType;
    for (size_t i = 0; i < 5; i++)
    {
        outParameter[i] = argv[i];
    }
    if (outParameter[4] == "NM")
    {
        magType = MagmomType::NonMagnetic;
    }
    else if ((outParameter[4] == "FM") | (outParameter[4] == "AFM"))
    {
        magType = MagmomType::Magnetic;
    }
    else
    {
        magType = MagmomType::Uninitialized;
    }
    DoscarProcessor *doscar;
    doscar = new DoscarProcessor(magType, &location);
    doscar->MergeDoscarTable();
    doscar->PrintMergedTable(&outFileName, outParameter);
    delete doscar;
    return 0;
}

