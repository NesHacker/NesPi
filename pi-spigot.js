function toHex (number) {
  return `${number.toString(16).toUpperCase()}`
}

/**
 * JavaScript implementation of pi-spigot.
 * @see https://www.maa.org/sites/default/files/pdf/pubs/amm_supplements/Monthly_Reference_12.pdf
 * @param {number} n Number of digits to calculate.
 * @returns {string} A string containing `n` digits of pi.
 */
function piSpigot (n) {
  const len = (10*n / 3) | 0
  const A = []
  const digits = []

  for (let k = 0; k < len+1; k++) {
    A.push(2)
  }

  let nines = 0
  let predigit = 0

  for (let j = n; j >= 1; j--) {
    let q = 0
    let z = 0

    for (let i = len; i >= 1; i--) {
      let left = 10 * A[i]
      let right = q * i
      z = left + right

      let twoI = 2 * i
      let twoIMinusOne = twoI - 1

      A[i] = z % twoIMinusOne
      q = (z / twoIMinusOne) | 0
    }

    A[1] = q % 10
    q = (q / 10) | 0

    if (q == 9) {
      nines++
    } else if (q == 10) {
      digits.push(predigit + 1)
      for (let k = 1; k <= nines; k++) {
        digits.push(0)
      }
      predigit = 0
      nines = 0
    } else {
      digits.push(predigit)
      predigit = q
      if (nines != 0) {
        for (let k = 1; k <= nines; k++) {
          digits.push(9)
        }
        nines = 0
      }
    }
  }

  const checksum = toHex(digits.reduce((a, b) => a + b) % 0x100)
  console.log('Checksum: ' + checksum)

  return digits[1] + '.' + digits.slice(2).join('')
}

/**
 * Tests to ensure `piSpigot` correctly produces digits of pi.
 * @param {number} n Number of digits to calculate.
 */
function test (n) {
  const spigotResult = piSpigot(n)
  const piDigits = `3.1415926535897932384626433832795028841971693993751058209749445923078164062862089986280348253421170679821480865132823066470938446095505822317253594081284811174502841027019385211055596446229489549303819644288109756659334461284756482337867831652712019091456485669234603486104543266482133936072602491412737245870066063155881748815209209628292540917153643678925903600113305305488204665213841469519415116094330572703657595919530921861173819326117931051185480744623799627495673518857527248912279381830119491298336733624406566430860213949463952247371907021798609437027705392171762931767523846748184676694051320005681271452635608277857713427577896091736371787214684409012249534301465495853710507922796892589235420199561121290219608640344181598136297747713099605187072113499999983729780499510597317328160963185950244594553469083026425223082533446850352619311881710100031378387528865875332083814206171776691473035982534904287554687311595628638823537875937519577818577805321712268066130019278766111959092164201989`
  const isCorrect = piDigits.slice(0, n) === spigotResult
  if (isCorrect) {
    console.log('Correctly calculated digits.')
  } else {
    console.error('INCORRECT DIGIT CALCULATION!')
    console.error(spigotResult)
    console.error(piDigits.slice(0, n))
  }
}

test(960)
