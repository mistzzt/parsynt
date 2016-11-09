#include <iostream>
#include <sstream>
#include <cmath>
#include <tbb/tbb.h>

using namespace tbb;
 
class ApplyFoo {
    float *const my_a;
public:
    void operator()( const blocked_range<size_t>& r ) const {
        float *a = my_a;

	double s = 0.0;
        for( size_t i=r.begin(); i!=r.end(); ++i ) 
        {
	    // for (int j = 0; j < 1000000; j++)
	    //	a[i] = std::sin(a[i]);
		s = (s + a[i]) / 2.0;
	} 
    }
    ApplyFoo( float a[] ) :
        my_a(a)
    {}
};


void ParallelApplyFoo( float a[], size_t n ) {
    parallel_for(blocked_range<size_t>(0,n), ApplyFoo(a));
}

class SumFoo {
    float* my_a;
public:
    double my_sum; 
    int b, e;

    void operator()( const blocked_range<size_t>& r ) 
    {


        float *a = my_a;
        float sum = my_sum;
        size_t end = r.end();

	std::stringstream stream;
	stream << "operating on: [" << r.begin() << ".." << r.end() << "]";
	stream << " initial sum is:" << sum;
	stream << " (" << b << " .. " << e << ") ->";
	if (b < 0 || r.begin() < b)
	    b = r.begin();
	if (e < 0 || r.end() > e)
	    e = r.end();

	stream << " (" << b << " .. " << e << ")\n";
    std::cout << stream.str();

        for (size_t i=r.begin(); i!=end; ++i) 
            //sum = (sum + a[i]) / 2.0; 
            sum += a[i]; 
            
        my_sum = sum;    
    }
 
    SumFoo( SumFoo& x, split ) : my_a(x.my_a), my_sum(0) {}
 
    void join(const SumFoo& y) 
    { 
	std::stringstream stream;
	stream << "\n\njoining: [" << b << ".." << e << "] and [" << y.b << ".." << y.e << "]\n";
	stream << "\n>";
	if ((y.b < e && y.e > b) || (b < y.e && e > y.b))
	    stream << "*\n";
	std::cout << stream.str();

	double tmp = my_sum;
	for (int i = y.b; i < y.e; i++)
	    tmp = tmp / 2.0;

	my_sum = tmp + y.my_sum;
	// e = y.e;
	if (y.b < b)
	    b = y.b;
	if (y.e > e)
	    e = y.e;
    }
             
    SumFoo(float a[]) :
        my_a(a), my_sum(0), b(-1), e(-1)
    {  std::cout << "\n#\n";}
};

double ParallelSumFoo(float a[], size_t n) 
{
    SumFoo sf(a);
    parallel_reduce( blocked_range<size_t>(0,n), sf );
    return sf.my_sum;
}


double SerialSumFoo(float a[], size_t n) 
{
    double sum = 0.0;
    for (int i = 0; i < n; i++)
	sum = (sum + a[i]) / 2.0;
    return sum;
}

int main(int argc, const char *argv[])
{
    tbb::task_scheduler_init init(1);
    if (argc < 2)
    {
	std::cout << "no array size specified\n";
	exit(1);
    }

    int size = std::atoi(argv[1]);

    std::cout << "array size: " << size << "\n"; 

    float *f_array = new float[size];

    for (int i = 0; i < size; i++)
	f_array[i] = 1;
    
    double sum = ParallelSumFoo(f_array, size);

    std::cout << "parallel sum: " << sum << "\n";

    double ssum = SerialSumFoo(f_array, size);
 
    std::cout << "serial sum: " << ssum << "\n";

    delete f_array;
}
